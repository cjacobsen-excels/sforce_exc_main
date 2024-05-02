({
  listViewInit: function(component, event, helper) {
    //If this component hasn't been extended, initialize
    if (component.get('v.body').length === 0) {
      helper.initialize(component);
      helper.addHook(component, 'afterLoadSchema', helper.afterLoadSchemaHook);
      helper.addHook(component, 'afterGetAll', helper.addDefaultColumns);
    }
  },
  onHookEvent: function(component, event, helper) {
    let payload = event.getParam('payload');
    helper.addHooks(component, payload);
  }
})