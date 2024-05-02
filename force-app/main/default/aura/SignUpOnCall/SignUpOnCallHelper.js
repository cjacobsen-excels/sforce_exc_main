({
  beforeLoadSchema: function (component) {
    component.set("v.schemaData", {
      header: {
        icon: "standard:data_integration_hub",
        iconSize: "medium",
        subtitle: "Sets Qualified Faculty",
        title: "Add Clinical Instructor",
        search: true,
        refresh: true,
        filter: false,
        new: false,
        expand: false,
        actions: []
      },
      queries: [
        {
          fields: ["Id", "Name"],
          sObjectType: "RecordType",
          whereClause: "sObjectType = 'hed__Course_Enrollment__c' AND Name = 'Faculty'"
        },
        {
          fields: ["Id", "hed__Facility__c", "hed__Course__c", "hed__End_Date__c"],
          sObjectType: "hed__Course_Offering__c",
          whereClause: "Id = '$RECORDID'"
        },
        {
          fields: [
            "Id",
            "Confirmed_Course_Connection__c",
            "hed__Course_Offering__c",
            "Clinical_Weekend_Name__c",
            "End_Date__c",
            "Start_Date__c",
            "Status__c"
          ],
          sObjectType: "hed__Course_Offering_Schedule__c",
          whereClause: "hed__Course_Offering__c = '$RECORDID' AND Status__c IN ('Active', 'Planned')",
          orderBy: "Start_Date__c ASC"
        },
        {
          fields: ["Id", "FirstName", "LastName"],
          sObjectType: "Contact",
          orderBy: "LastName ASC",
          whereClause: "CE_Faculty__c = true AND Faculty_User_Record__c = '$USERID'",
          subQueries: [
            {
              fields: ["Id", "hed__Contact__c", "Credential_Name__c", "hed__End_Date__c", "Active_SON__c"],
              sObjectType: "hed__Attribute__c",
              whereClause: "hed__Contact__c = '$PARENT.Id' AND Active_SON__c = true"
            },
            {
              fields: [
                //clinical name?
                "Id",
                "RecordTypeId",
                "hed__Course_Offering__c",
                "Course_Offering_Schedule__c",
                "Course_Offering_Schedule__r.Start_Date__c as scheduleStartDate",
                "Course_Offering_Schedule__r.End_Date__c as schduleEndDate",
                "Course_Offering_Schedule__r.Clinical_Weekend_Name__c as scheduleName",
                "hed__Status__c",
                "hed__Contact__c",
                "Course_Date__c",
                "Course_End_Date__c"
              ],
              sObjectType: "hed__Course_Enrollment__c",
              whereClause: "hed__Contact__c = '$PARENT.Id' AND Course_End_Date__c > TODAY"
            }
          ]
        }
      ]
    });

    this.setAttributeProp(component, "loadingStatus.loading", true);
  },

  processData: function (component) {
    let vm = component.get("v.viewModel");
    this.splitRecordsByType(component);
    component.set("v.viewModel", vm);

    if (vm.data.hasOwnProperty("contact")) {
      let filteredContacts = [];
      let i = 0;
      for (let contact of vm.data.contact) {
        filteredContacts.push({
          name: contact.value.FirstName + " " + contact.value.LastName,
          index: i,
          contactId: contact.value.Id
        });
        i++;
      }
      component.set("v.filteredContacts", filteredContacts);
    }

    if (!vm.data.hasOwnProperty("hed__course_offering__c")) {
      this.throwError("The course offering record was not returned");
    } else {
      const offering = vm.data.hed__course_offering__c[0].value;
      let queries = { queries: [] };
      if (offering.hasOwnProperty("hed__Course__c")) {
        queries.queries.push({
          fields: ["Id", "Credential_Name__c", "Requirement_Status__c"],
          sObjectType: "Requirements__c",
          whereClause: "Course__c = '" + offering.hed__Course__c + "'"
        });
      }
      if (offering.hasOwnProperty("hed__Facility__c")) {
        queries.queries.push({
          fields: ["Id", "Credential_Name__c", "Requirement_Status__c"],
          sObjectType: "Requirements__c",
          whereClause: "Facility__c = '" + offering.hed__Facility__c + "'"
        });
      }

      this.rawQuery(component, queries).then((data) => {
        this.log(data);
        let requirements = [];
        let reqObject = [];
        for (let req of data.data.items) {
          let cred = req.value.Credential_Name__c;
          if (requirements.indexOf(cred) === -1) {
            requirements.push(cred);
            reqObject.push({
              credName: cred,
              hard: req.value.Requirement_Status__c === "Major Req"
            });
          }
        }
        component.set("v.requirements", reqObject);
        this.processUserRequirements(component, vm, reqObject);
      });
    }
  },

  processUserRequirements: function (component, vm, reqObject) {
    let hasHardReqs = false;
    let hasSoftReqs = false;
    for (let req of reqObject) {
      if (req.hard) {
        hasHardReqs = true;
      } else {
        hasSoftReqs = true;
      }
    }
    const offering = vm.data.hed__course_offering__c[0].value;
    const endDate = offering.hed__End_Date__c;

    if (typeof vm.data.contact !== "undefined") {
      for (let contact of vm.data.contact) {
        let creds = [];
        for (let credential of contact.children) {
          if (
            credential.value.attributes.type == "hed__Attribute__c" &&
            (typeof credential.value.hed__End_Date__c === "undefined" ||
              endDate <= credential.value.hed__End_Date__c)
          ) {
            creds.push(credential.value.Credential_Name__c);
          }
        }
        let passesSoft = true;
        let passesHard = true;
        let failures = [];
        for (let req of reqObject) {
          if (creds.indexOf(req.credName) === -1) {
            failures.push(req.credName);
            if (req.hard) {
              passesHard = false;
            } else {
              passesSoft = false;
            }
          }
        }
        let failureStr = failures.join(", ");
        contact.properties = {
          passesSoft: passesSoft,
          passesHard: passesHard,
          failures: failures,
          selected: false,
          score: 0,
          failureStr: failureStr,
          credStr: creds.join(", ")
        };
      }
    }

    component.set("v.viewModel", vm);
    this.processSchedules(component, vm);
  },

  processSchedules: function (component, vm) {
    if (vm.data.hasOwnProperty("contact")) {
      for (let faculty of vm.data.contact) {
        if (typeof faculty.properties.schedules == "undefined") {
          faculty.properties.schedules = [];
        }

        if (!vm.data.hasOwnProperty("hed__course_offering_schedule__c")) {
          continue;
        }
        for (let schedule of vm.data.hed__course_offering_schedule__c) {
          let alreadyConfirmed = typeof schedule.value.Confirmed_Course_Connection__c != "undefined";

          // determine if this faculty should be able to sing-up as on call
          let foundOverlappingDates = false;

          // skip checking for overlapping dates if the course is already confirmed
          if (!alreadyConfirmed) {
            let scheduleStart = Date.parse(schedule.value.Start_Date__c);
            let scheduleEnd = Date.parse(schedule.value.End_Date__c);

            // verify if any existing connections overlap with this schedules dates
            for (let connection of faculty.children) {
              if (connection.value.attributes.type == "hed__Course_Enrollment__c") {
                // make sure there are actually dates (null check)
                if (
                  !connection.value.hasOwnProperty("Course_Offering_Schedule__r") ||
                  !connection.value.Course_Offering_Schedule__r.hasOwnProperty("Start_Date__c") ||
                  !connection.value.Course_Offering_Schedule__r.hasOwnProperty("End_Date__c")
                ) {
                  continue;
                }

                let connectionStart = Date.parse(connection.value.Course_Offering_Schedule__r.Start_Date__c);
                let connectionEnd = Date.parse(connection.value.Course_Offering_Schedule__r.End_Date__c);
                // date check
                if (connectionStart < scheduleEnd && connectionEnd > scheduleStart) {
                  foundOverlappingDates = true;
                  break;
                }
              }
            }
          }

          let scheduleName = schedule.value.Clinical_Weekend_Name__c + " (";
          scheduleName += this.getFormattedDate(schedule.value.Start_Date__c) + " - ";
          scheduleName += this.getFormattedDate(schedule.value.End_Date__c) + ")";

          faculty.properties.schedules.push({
            scheduleName: scheduleName,
            scheduleId: schedule.value.Id,
            checked: alreadyConfirmed,
            overLappingDates: foundOverlappingDates,
            alreadyConfirmed: alreadyConfirmed,
            startDate: schedule.value.Start_Date__c,
            endDate: schedule.value.End_Date__c
          });
        }
      }

      component.set("v.viewModel", vm);
      component.set("v.selectedUser", vm.data.contact[0]);
    }
    this.setAttributeProp(component, "loadingStatus.loading", false);
  },

  getFormattedDate: function (dateString) {
    // set date up because the dateString doesn't have any timezone info
    const offset = new Date(dateString).getTimezoneOffset();
    let date = new Date(dateString);
    date.setMinutes(date.getMinutes() + offset);

    console.log(dateString, offset, new Date(dateString), date);

    // get values
    let year = date.getFullYear();
    let month = (1 + date.getMonth()).toString();
    month = month.length > 1 ? month : "0" + month;
    let day = date.getDate().toString();
    day = day.length > 1 ? day : "0" + day;

    // return our date formatted how we want!
    return month + "/" + day + "/" + year;
  },

  closeModal: function (component) {
    var dismissActionPanel = $A.get("e.force:closeQuickAction");
    dismissActionPanel.fire();
  }
});