({
  beforeLoadSchema: function (component) {
    component.set("v.schemaData", {
      header: {
        icon: "standard:data_integration_hub",
        iconSize: "medium",
        subtitle: "Course Connections",
        title: "Connection Builder",
        search: true,
        refresh: true,
        filter: false,
        new: false,
        expand: false,
        actions: [
          {
            icon: "utility:edit",
            function: "toggleEditMode",
            stateful: true,
            active: false
          }
        ]
      },
      queries: [
        {
          fields: [
            "Id",
            "hed__Course_Offering__c",
            "hed__Status__c",
            "hed__Contact__c"
          ],
          sObjectType: "hed__Course_Enrollment__c",
          whereClause: "hed__Course_Offering__c = '$RECORDID'"
        },
        {
          fields: ["Id", "FirstName", "LastName"],
          sObjectType: "Contact",
          orderBy: "LastName ASC",
          whereClause: "CE_Faculty__c = true",
          subQueries: [
            {
              fields: [
                "Id",
                "hed__Contact__c",
                "Credential_Name__c",
                "hed__End_Date__c",
                "Active_SON__c"
              ],
              sObjectType: "hed__Attribute__c",
              whereClause:
                "hed__Contact__c = '$PARENT.Id' AND Active_SON__c = true"
            }
          ]
        },
        {
          fields: [
            "Id",
            "hed__Facility__c",
            "hed__Course__c",
            "hed__End_Date__c"
          ],
          sObjectType: "hed__Course_Offering__c",
          whereClause: "Id = '$RECORDID'"
        }
      ]
    });
    this.setAttributeProp(component, "loadingStatus.loading", true);
  },

  afterGetAll: function (component) {
    this.runHooks(component, "afterGetAll");
  },

  processData: function (component) {
    let vm = component.get("v.viewModel");
    this.splitRecordsByType(component);
    component.set("v.viewModel", vm);
    //get all course ids
    let queries = {
      queries: []
    };
    if (vm.data.hasOwnProperty("contact")) {
      let filteredContacts = [];
      let i = 0;
      for (let contact of vm.data.contact) {
        filteredContacts.push({
          name: contact.value.FirstName + " " + contact.value.LastName,
          index: i
        });
        i++;
      }
      component.set("v.filteredContacts", filteredContacts);
    }

    if (!vm.data.hasOwnProperty("hed__course_offering__c")) {
      this.throwError("The course offering record was not returned");
    } else {
      const offering = vm.data.hed__course_offering__c[0].value;
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
    let existingUsers = [];
    if (typeof vm.data.contact !== "undefined") {
      for (let contact of vm.data.contact) {
        let creds = [];
        for (let credential of contact.children) {
          if (
            typeof credential.value.hed__End_Date__c === "undefined" ||
            endDate <= credential.value.hed__End_Date__c
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

        if (vm.data.hasOwnProperty("hed__course_enrollment__c")) {
          for (let connection of vm.data.hed__course_enrollment__c) {
            if (connection.value.hed__Contact__c === contact.value.Id) {
              console.log("match");
              existingUsers.push(contact.value.Id);
              contact.properties.selected = true;
              contact.properties.status = connection.value.hed__Status__c;
            }
          }
        }
      }
    }
    const editMode = existingUsers.length === 0;
    component.set("v.editMode", editMode);
    component.set("v.viewModel", vm);
    component.set("v.existingUsers", existingUsers);
    this.setAttributeProp(component, "loadingStatus.loading", false);
    this.log(vm);
  },

  toggleEditMode: function (component) {
    let editMode = component.get("v.editMode");
    if (!editMode) {
      component.set("v.editMode", true);
    } else {
      if (
        component.get("v.changes") &&
        !confirm("Are you sure you want to undo your changes?")
      ) {
        this.toggleEditButton(component);
        return;
      }
      component.set("v.editMode", false);
      component.set("v.changes", false);
    }
  },

  getChanges: function (component) {
    this.setAttributeProp(component, "loadingStatus.loading", true);
    let vm = component.get("v.viewModel");
    let oldUsers = component.get("v.existingUsers");
    let selected = vm.data.contact.filter(
      (contact) => contact.properties.selected
    );

    let contactsToAdd = selected.filter(
      (contact) => oldUsers.indexOf(contact.value.Id) === -1
    );
    let contactsToRemove = oldUsers.filter((oldUserId) => {
      for (let contact of selected) {
        if (contact.value.Id === oldUserId) {
          return false;
        }
      }
      return true;
    });
    this.rawQuery(component, {
      queries: [
        {
          fields: ["DeveloperName", "Description_Text_Area__c"],
          sObjectType: "Faculty_Management__mdt",
          whereClause: "DeveloperName = 'CPNE_Qual_Task'",
          orderBy: ""
        },
        {
          fields: ["Id"],
          sObjectType: "Group",
          whereClause: "DeveloperName = 'CPNE_Qualification_Queue'"
        }
      ]
    }).then((data) => {
      if (data.data.items.length !== 2) {
        this.throwError(
          component,
          'Missing Faculty Management Setting: "CPNE_Qual_Task"'
        );
      }
      if (contactsToRemove.length > 0) {
        this.removeConnections(component, contactsToRemove);
      }
      this.createConnections(
        component,
        contactsToAdd,
        data.data.items[0].value.Description_Text_Area__c,
        data.data.items[1].value.Id
      );
    });
  },

  createConnections: function (component, contactsToAdd, taskMessage, queueId) {
    let data = [];
    let vm = component.get("v.viewModel");
    let facility =
      vm.data.hed__course_offering__c[0].value.hed__Facility__c || "";
    let course = vm.data.hed__course_offering__c[0].value.hed__Course__c || "";
    let offering = vm.data.hed__course_offering__c[0].value.Id;
    for (let contact of contactsToAdd) {
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
          Qualification_Details__c: contact.properties.credStr,
          Faculty__c: contact.value.Id,
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
            type: "hed__Course_Enrollment__c"
          },
          hed__Status__c: "Pending",
          hed__Contact__c: contact.value.Id,
          hed__Course_Offering__c: offering
        }
      });
      if (reqStatus !== "Met") {
        data.push({
          modified: true,
          toDelete: false,
          children: [],
          properties: null,
          value: {
            attributes: {
              type: "Task"
            },
            Status: "Not Started",
            Priority: "Normal",
            OwnerId: queueId,
            WhatId: offering,
            WhoId: contact.value.Id,
            Subject: "CPNE Missing Requirements",
            Description: taskMessage
          }
        });
      }
    }
    console.log("to create:");
    this.log(data);
    this.standardizeCallout(component, "upsertAll", {
      viewModel: JSON.stringify({ data: { items: data }, queries: [] })
    })
      .then((data) => {
        this.showToast(
          component,
          "Success",
          "Records successfully updated",
          "success"
        );
        this.getAll(component);
      })
      .catch((e) => {});
  },

  removeConnections: function (component, contactsToRemove) {
    let data = [];
    let vm = component.get("v.viewModel");
    if (vm.data.hasOwnProperty("hed__course_enrollment__c")) {
      let offereingsToDelete = vm.data.hed__course_enrollment__c
        .filter(
          (enrollment) =>
            contactsToRemove.indexOf(enrollment.value.hed__Contact__c) !== -1
        )
        .map((v) => {
          v.toDelete = true;
          v.modified = true;
          return v;
        });
      this.standardizeCallout(component, "upsertAll", {
        viewModel: JSON.stringify({
          data: { items: offereingsToDelete },
          queries: []
        })
      })
        .then((data) => {})
        .catch((e) => {});
    }
  },

  search: function (component, query) {
    console.time("search performance");
    var searchLibrary = this.findComponent(
      component,
      "searchLibrary"
    ).getLibrary();
    let viewModel = component.get("v.viewModel");
    // @todo: get settings from dynamic config and update the search library
    searchLibrary.initialize(viewModel.queries[1].fieldDescribes);
    if (query !== "") {
      viewModel.data.contact = searchLibrary.search(
        query,
        viewModel.data.contact,
        -1
      );
    } else {
      viewModel.data.contact.map((c) => {
        c.properties.score = 0;
        return c;
      });
    }
    component.set("v.viewModel", viewModel);
    console.timeEnd("search performance");
    this.log(viewModel);
  },

  closeModal: function (component) {
    var dismissActionPanel = $A.get("e.force:closeQuickAction");
    dismissActionPanel.fire();
  }
});