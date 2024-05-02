({
  beforeLoadSchema: function (component) {
    component.set("v.schemaData", {
      header: {
        icon: "standard:data_integration_hub",
        iconSize: "medium",
        subtitle: "Sets Qualified Factulty",
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
          fields: [
            "Id",
            "hed__Facility__c",
            "hed__Faculty__c",
            "hed__Course__c",
            "hed__End_Date__c"
          ],
          sObjectType: "hed__Course_Offering__c",
          whereClause: "Id = '$RECORDID'",
          subQueries: [
            {
              fields: [
                "Id",
                "Name",
                "Active_Inactive__c",
                "End_Date__c",
                "Course__c",
                "Faculty__c",
                "Faculty__r.FirstName",
                "Faculty__r.LastName"
              ],
              sObjectType: "Qualified_Faculty__c",
              whereClause:
                "Course__c = '$PARENT.hed__Course__c' AND Active_Inactive__c = 'Active' AND Faculty__r.Qualifications_Met__c=true"
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

    if (!vm.data.hasOwnProperty("hed__course_offering__c")) {
      this.throwError("The course offering record was not returned");
    } else {
      let requirements = [];
      let reqObject = []; // list of requirements for the course offering
      let filteredContacts = []; // list of contacts for dropdown

      // only children of hed__course_offering__c[0] are qualified faculty records
      let i = 0;
      let contactIds = [];
      for (let item of vm.data.hed__course_offering__c[0].children) {
        filteredContacts.push({
          name:
            item.value.Faculty__r.FirstName +
            " " +
            item.value.Faculty__r.LastName,
          index: i,
          id: item.value.Faculty__c
        });
        contactIds.push(item.value.Faculty__c);
        item.properties = { credentials: [] }; // preset the credentials array
        i++;
      }

      // let's get the requirements and contact attributes
      let offering = vm.data.hed__course_offering__c[0].value;
      let facilityClause =
        offering.hed__Facility__c != null
          ? " OR Facility__c = '" + offering.hed__Facility__c + "' "
          : "";
      let queries = {
        queries: [
          {
            fields: ["Id", "Credential_Name__c", "Requirement_Status__c"],
            sObjectType: "Requirements__c",
            whereClause:
              "(Course__c = '" +
              offering.hed__Course__c +
              "'" +
              facilityClause +
              ")"
          },
          {
            fields: [
              "Id",
              "hed__Contact__c",
              "Credential_Name__c",
              "hed__End_Date__c",
              "Active_SON__c"
            ],
            sObjectType: "hed__Attribute__c",
            whereClause: "hed__Contact__c IN ('" + contactIds.join("','") + "')"
          }
        ]
      };

      this.rawQuery(component, queries).then((data) => {
        for (let item of data.data.items) {
          // loop over requirements and put them in the reqObject
          if (item.value.attributes.type == "Requirements__c") {
            let cred = item.value.Credential_Name__c;
            if (requirements.indexOf(cred) === -1) {
              requirements.push(cred);
              reqObject.push({
                credName: cred,
                hard: item.value.Requirement_Status__c === "Major Req"
              });
            }
          }

          // loop over attributes and put them in the view model
          if (item.value.attributes.type == "hed__Attribute__c") {
            for (let faculty of vm.data.hed__course_offering__c[0].children) {
              if (item.value.hed__Contact__c == faculty.value.Faculty__c) {
                if (
                  typeof item.value.hed__End_Date__c === "undefined" ||
                  vm.data.hed__course_offering__c[0].value.hed__End_Date__c <=
                    item.value.hed__End_Date__c
                ) {
                  faculty.properties.credentials.push(
                    item.value.Credential_Name__c
                  );
                }
              }
            }
          }
        }
        component.set("v.filteredContacts", filteredContacts);
        component.set("v.requirements", reqObject);
        component.set("v.viewModel", vm);
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

    for (let item of vm.data.hed__course_offering__c[0].children) {
      let creds = item.properties.credentials;
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
      item.properties.passesSoft = passesSoft;
      item.properties.passesHard = passesHard;
      item.properties.failures = failures;
      item.properties.selected = false;
      item.properties.score = 0;
      item.properties.failureStr = failureStr;
      item.properties.credStr = creds.join(", ");
    }

    component.set("v.viewModel", vm);
    this.setAttributeProp(component, "loadingStatus.loading", false);
  },

  closeModal: function (component) {
    var dismissActionPanel = $A.get("e.force:closeQuickAction");
    dismissActionPanel.fire();
  }
});