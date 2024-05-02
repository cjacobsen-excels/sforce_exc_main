({
  onInit: function (component, event, helper) {
    helper.initialize(component);
    helper.addHook(component, "afterGetAll", helper.processData);
  },

  onFocus: function (component, event, helper) {
    component.set("v.showDropdown", true);
  },

  onBlur: function (component, event, helper) {
    setTimeout(() => {
      component.set("v.showDropdown", false);
    }, 300);
  },

  checkBoxChanged: function (component, event, helper) {
    let selectedUser = component.get("v.selectedUser");
    let shouldEnable = false;

    for (let schedule of selectedUser.properties.schedules) {
      if (!schedule.alreadyConfirmed && schedule.checked && !schedule.overLappingDates) {
        shouldEnable = true;
        break;
      }
    }

    if (shouldEnable) {
      component.set("v.disableCreate", false);
    } else {
      component.set("v.disableCreate", true);
    }
  },

  onContactSelect: function (component, event, helper) {
    if (event.getParam("type").indexOf("dropdown_select") === -1) return;
    const payload = event.getParam("data");
    let vm = component.get("v.viewModel");
    let selectedUser = vm.data.contact[payload.index];
    helper.log(selectedUser);
    component.set("v.selectedUser", selectedUser);
    component.set("v.query", payload.name);
  },

  nextScreen: function (component, event, helper) {
    let state = component.get("v.state");
    helper.setLoadingStatus(component, "saving");
    component.set("v.disableCreate", true);

    if (state === 0) {
      component.set("v.state", 1);
      let vm = component.get("v.viewModel");
      let selectedUser = component.get("v.selectedUser");
      let offering = vm.data.hed__course_offering__c[0].value.Id;
      let facility = vm.data.hed__course_offering__c[0].value.hed__Facility__c || "";
      let course = vm.data.hed__course_offering__c[0].value.hed__Course__c || "";
      let data = [];

      let newEnrollmentCount = 0;
      let reqStatus = !selectedUser.properties.passesHard
        ? "Not Met - Major Req Missing"
        : !selectedUser.properties.passesSoft
        ? "Not Met - Minor Req Missing"
        : "Met";

      let facultyRecordTypeId = "";
      if (vm.data.hasOwnProperty("recordtype")) {
        facultyRecordTypeId = vm.data.recordtype[0].value.Id;
      }

      for (let schedule of selectedUser.properties.schedules) {
        if (!schedule.alreadyConfirmed && schedule.checked && !schedule.overLappingDates) {
          newEnrollmentCount++;
          data.push({
            modified: true,
            toDelete: false,
            children: [],
            properties: null,
            value: {
              attributes: {
                type: "hed__Course_Enrollment__c"
              },
              hed__Status__c: "Pending",
              hed__Contact__c: selectedUser.value.Id,
              hed__Course_Offering__c: offering,
              Role__c: "Clinical_Instructor_On_Call",
              Qualification_Status__c: reqStatus,
              Course_Offering_Schedule__c: schedule.scheduleId,
              RecordTypeId: facultyRecordTypeId
            }
          });
        }
      }

      if (newEnrollmentCount > 0) {
        data.push({
          modified: true,
          toDelete: false,
          children: [],
          properties: null,
          value: {
            attributes: {
              type: "CPNE_Qualification__c"
            },
            Requirements_Status__c: reqStatus,
            Qualification_Details__c:
              "Has: " + selectedUser.properties.credStr + ". Missing: " + selectedUser.properties.failureStr,
            Faculty__c: selectedUser.value.Id,
            Facility__c: facility,
            Course_Offering__c: offering,
            Course__c: course
          }
        });

        let query = [];

        query.push(
          {
            sObjectType: "CPNE_Qualification__c",
            fields: ["Id"],
            whereClause:
              "Faculty__c = '" + selectedUser.value.Id + "' AND Course_Offering__c = '" + offering + "'",
            orderBy: "SystemModstamp DESC",
            limitClause: 1
          },
          {
            sObjectType: "hed__Course_Enrollment__c",
            fields: ["Id", "Course_Offering_Schedule__c"],
            whereClause:
              "hed__Contact__c = '" +
              selectedUser.value.Id +
              "' AND hed__Course_Offering__c = '" +
              offering +
              "' AND Role__c = 'Clinical_Instructor_On_Call'",
            orderBy: "SystemModstamp DESC",
            limitClause: newEnrollmentCount
          }
        );

        helper
          .standardizeCallout(component, "upsertAll", {
            viewModel: JSON.stringify({
              data: { items: data },
              queries: query
            })
          })
          .then((data) => {
            let schedulesToUpdate = [];

            // now update the offerings to reflect they are confirmed
            for (let item of data.data.items) {
              if (item.value.attributes.type == "hed__Course_Enrollment__c") {
                // let enrollmentId = saveResult.id;

                schedulesToUpdate.push({
                  modified: true,
                  toDelete: false,
                  children: [],
                  properties: null,
                  value: {
                    attributes: {
                      type: "hed__Course_Offering_Schedule__c"
                    },
                    Id: item.value.Course_Offering_Schedule__c,
                    Confirmed_Course_Connection__c: item.value.Id
                  }
                });
              } else if (item.value.attributes.type == "CPNE_Qualification__c") {
                component.set("v.qualificationId", item.value.Id);
              }
            }

            helper
              .standardizeCallout(component, "upsertAll", {
                viewModel: JSON.stringify({
                  data: { items: schedulesToUpdate },
                  queries: []
                })
              })
              .then((data) => {
                // do nothing
              });

            component.set("v.state", 2);
          });
      }
    }
  }
});