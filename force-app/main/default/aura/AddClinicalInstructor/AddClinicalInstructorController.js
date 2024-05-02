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

  onChange: function (component, event, helper) {},

  onContactSelect: function (component, event, helper) {
    if (event.getParam("type").indexOf("dropdown_select") === -1) return;
    const payload = event.getParam("data");
    let vm = component.get("v.viewModel");
    let selectedUser =
      vm.data.hed__course_offering__c[0].children[payload.index];
    component.set("v.selectedUser", selectedUser);
    component.set("v.disableSubmit", false);
    component.set("v.query", payload.name);
  },

  nextScreen: function (component, event, helper) {
    component.set("v.disableSubmit", true);
    let state = component.get("v.state");
    helper.setLoadingStatus(component, "saving");
    if (state === 0) {
      component.set("v.state", 1);
      let vm = component.get("v.viewModel");
      let contact = component.get("v.selectedUser");
      let data = [];
      let facility =
        vm.data.hed__course_offering__c[0].value.hed__Facility__c || "";
      let course =
        vm.data.hed__course_offering__c[0].value.hed__Course__c || "";
      let offering = vm.data.hed__course_offering__c[0].value.Id;

      let reqStatus = !contact.properties.passesHard
        ? "Not Met - Major Req Missing"
        : !contact.properties.passesSoft
        ? "Not Met - Minor Req Missing"
        : "Met";

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
            "Has: " +
            contact.properties.credStr +
            ". Missing: " +
            contact.properties.failureStr,
          Faculty__c: contact.value.Faculty__c,
          Facility__c: facility,
          Course_Offering__c: offering,
          Course__c: course
        }
      });

      data.push({
        modified: true,
        toDelete: false,
        children: [],
        properties: null,
        value: {
          attributes: {
            type: "hed__Course_Offering__c"
          },
          Id: offering,
          Qualified_Faculty__c: contact.value.Id,
          hed__Faculty__c: ""
        }
      });

      let query = [
        {
          sObjectType: "CPNE_Qualification__c",
          fields: ["Id"],
          whereClause:
            "Faculty__c = '" +
            contact.value.Faculty__c +
            "' AND Course_Offering__c = '" +
            offering +
            "'",
          orderBy: "SystemModstamp DESC",
          limitClause: 1
        }
      ];

      helper
        .standardizeCallout(component, "upsertAll", {
          viewModel: JSON.stringify({
            data: { items: data },
            queries: query
          })
        })
        .then((data) => {
          component.set("v.qualificationId", data.data.items[0].value.Id);
          component.set("v.state", 2);
        });
    }
  }
});