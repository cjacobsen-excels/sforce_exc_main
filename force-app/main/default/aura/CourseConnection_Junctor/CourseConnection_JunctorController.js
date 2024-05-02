({
  onInit: function(component, event, helper) {
    helper.initialize(component);
    helper.addHook(component, 'afterGetAll', helper.processData);
  },


  onCheckboxToggle: function(component, event, helper) {
    let vm = component.get('v.viewModel');
    let contact = vm.data.contact[event.target.dataset['i']];
    if (event.target.checked) {
      contact.properties.selected = true;
    } else {
      contact.properties.selected = false;
    }
    component.set('v.viewModel', vm);
    component.set('v.changes', true);
  },

  cancelEdit: function(component, event, helper) {
    helper.setAttributeProp(component, 'loadingStatus.loading', true);
    helper.getAll(component);
  },

  saveChanges: function(component, event, helper) {
    helper.getChanges(component);
  },

  onFocus: function(component, event, helper) {
  
    component.set('v.showDropdown', true);
    
  },
  
  onBlur: function(component, event, helper) {
    setTimeout(() => {
      component.set('v.showDropdown', false);
    }, 300);
  },

  onChange: function(component, event, helper) {
    let vm = component.get('v.viewModel');
    let query = component.get('v.query');
    if (vm.data.hasOwnProperty('contact')) {
      let filteredContacts = [];
      let i=0;
      for (let contact of vm.data.contact) {
        let name = contact.value.FirstName + ' ' + contact.value.LastName;
        if (name.toLowerCase().indexOf(query) !== -1) {
          filteredContacts.push({
            name: name,
            index: i
          });
        }
        i++;
      }
      component.set('v.filteredContacts', filteredContacts);
    }
  },
  onContactSelect: function(component, event, helper) {
    if (event.getParam('type').indexOf('dropdown_select') === -1)
      return;
    const payload = event.getParam('data');
    helper.log(payload);
    let vm = component.get('v.viewModel');
    let selectedUser = vm.data.contact[payload.index];
    helper.log(selectedUser);
    component.set('v.selectedUser', selectedUser);
    component.set('v.query', payload.name);
  },
  nextScreen: function(component, event, helper) {
    let state = component.get('v.state');
    helper.setLoadingStatus(component, 'saving');
    if (state === 0) {
      component.set('v.state', 1);
      let vm = component.get('v.viewModel');
      let contact = component.get('v.selectedUser');
      let data = [];
      let facility = vm.data.hed__course_offering__c[0].value.hed__Facility__c || '';
      let course = vm.data.hed__course_offering__c[0].value.hed__Course__c || '';
      let offering = vm.data.hed__course_offering__c[0].value.Id;
      
      let reqStatus = !contact.properties.passesHard ? 'Not Met - Major Req Missing' :
        !contact.properties.passesSoft ? 'Not Met - Minor Req Missing' :
        'Met';
      data.push({
        modified: true,
        toDelete: false,
        children: [],
        properties: null,
        value: {
          attributes: {
            type: 'CPNE_Qualification__c'
          },
          Requirements_Status__c: reqStatus,
          Qualification_Details__c: 'Has: ' + contact.properties.credStr+'. Missing: ' + contact.properties.failureStr,
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
            type: 'hed__Course_Enrollment__c'
          },
          hed__Status__c: 'Pending',
          hed__Contact__c: contact.value.Id,
          hed__Course_Offering__c: offering,
          Role__c: component.get('v.role'),
          // Mentor__c: (component.get('v.mentorRequest')),
          Qualification_Status__c: reqStatus
        }
      });
      console.log('mentor request', component.get('v.mentorRequest'));

      let query = [{
        sObjectType: 'CPNE_Qualification__c', 
        fields: ['Id'],
        whereClause: 'Faculty__c = \'' + contact.value.Id + '\' AND Course_Offering__c = \''+ offering+'\'',
        orderBy: 'SystemModstamp DESC',
        limitClause: 1
      },{
        sObjectType: 'hed__Course_Enrollment__c', 
        fields: ['Id'],
        whereClause: 'hed__Contact__c = \'' + contact.value.Id + '\' AND hed__Course_Offering__c = \''+ offering+'\'',
        orderBy: 'SystemModstamp DESC',
        limitClause: 1
      }]
      helper.standardizeCallout(component, 'upsertAll', {viewModel: JSON.stringify({
        data: { items: data }, 
        queries: query
      })}).then( data => {
        console.log('post-upsert');
        helper.log(data);
        component.set('v.enrollmentId', data.data.items[1].value.Id);
        component.set('v.qualificationId', data.data.items[0].value.Id);
        if (reqStatus !== 'Met') {
          helper.rawQuery(component, {
            queries: [{
              fields: ['DeveloperName', 'Description_Text_Area__c', 'Name_Subject__c'],
              sObjectType: 'Faculty_Management__mdt',
              whereClause: 'DeveloperName = \'CPNE_Qual_Task\'',
              orderBy: '',
            }, {
              fields: ['Id'],
              sObjectType: 'Group',
              whereClause: 'DeveloperName = \'CPNE_Qualification_Queue\''
            }]
          }).then(d2 => {
            if (d2.data.items.length !== 2) {
              helper.throwError(component, 'Missing Faculty Management Setting: "CPNE_Qual_Task"');
            }
            let task = [{
              modified: true,
              toDelete: false,
              children: [],
              properties: null,
              value: {
                attributes: {
                  type: 'Task'
                },
                Status: 'Not Started',
                Priority: 'Normal',
                OwnerId: d2.data.items[1].value.Id,
                WhatId: data.data.items[0].value.Id,
                WhoId: contact.value.Id,
                Subject: d2.data.items[0].value.Name_Subject__c,
                Description: d2.data.items[0].value.Description_Text_Area__c
              }
            }];
            helper.standardizeCallout(component, 'upsertAll', {viewModel: JSON.stringify({
              data: { items: task },
              queries: query
            })}).then(data => {
              component.set('v.state', 2);
            });
          });
        } else {
          component.set('v.state', 2);
        }
      });
    }
  }
})