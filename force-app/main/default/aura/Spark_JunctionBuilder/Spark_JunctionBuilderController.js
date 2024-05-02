({
  onJunctionBuilderInit: function(component, event, helper) {
    helper.initialize(component);
    helper.addHook(component, 'afterLoadSchema', helper.afterSchemaSetup);
    helper.addHook(component, 'afterGetAll', helper.setupData);
  },
  cancelEdit: function(component, event, helper) {
    component.set('v.changes', false);
    component.set('v.editMode', false);
    helper.toggleEditButton(component);
  },
  saveChanges: function(component, event, helper) {
    helper.toggleEditButton(component);
    helper.setAttributeProp(component, 'loadingStatus.loading', true);
    helper.setAttributeProp(component, 'loadingStatus.saving', true);
    let junctionData = helper.getJunctionDataChanges(component);
    junctionData = helper.doModelProcessing(component, 'TO_SERVER', junctionData);
    helper.upsertJunctionData(component, junctionData);

  },
  onCheckboxToggle: function(component, event, helper) {
    let checkedList = component.get('v.checked');
    if (event.target.checked) {
      checkedList.push(event.target.dataset['id']);
    } else {
      checkedList.splice(checkedList.indexOf(event.target.dataset['id']), 1);
    }
    component.set('v.checked', checkedList);
    component.set('v.changes', true);
  }
})