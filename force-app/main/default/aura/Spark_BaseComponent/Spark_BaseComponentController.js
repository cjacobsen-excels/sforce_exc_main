({
  onRefreshComponent: function(component, event, helper) {
    helper.setupDataProcessors(component);
    helper.getAll(component, false, true);
  },
  onHookEvent: function(component, event, helper) {
    let payload = event.getParam('payload');
    helper.addHooks(component, payload);
  },
  getHelper: function(component, event, helper) {
    return helper;
  }
})