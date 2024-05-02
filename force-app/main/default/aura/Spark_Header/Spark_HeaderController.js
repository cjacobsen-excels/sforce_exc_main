({
  onInit: function(component, event, helper) {
    helper.initialize(component);
  },
  onSearch: function(component, event, helper) {
    let query = document.getElementById(component.getGlobalId() + '_search').value;
    if (typeof query === 'undefined' || query === null) query = '';
    helper.onSearch(component, query);
  },
  onActionClick: function(component, event, helper) {
    let node = event.target;
    while (node !== null && (!node.dataset || !node.dataset['i'])) {
      node = node.parentElement;
    }
    const i = node.dataset['i'];
    let schemaData = component.get('v.schemaData');
    let action = schemaData.header.actions[i];
    let parentComponent = component.get('v.parentComponent');
    let getHelper = parentComponent.get('c.getHelper');
    if (action.stateful) {
      action.active = (action.active) ? false : true;
    }
    schemaData.header.actions[i] = action;
    component.set('v.schemaData', schemaData);

    getHelper.setCallback(this, res => {
      let helper = res.getReturnValue();
      let args = [parentComponent];
      helper[action['function']].apply(this, args);
    });

    $A.enqueueAction(getHelper);
  },
  getHelper: function(component, event, helper) {
    return helper;
  }
})