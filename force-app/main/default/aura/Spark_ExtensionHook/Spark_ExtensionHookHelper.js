({
  initialize: function(component) {
    var hookEvent = component.getEvent("hookEvent");
    let payload = {
      beforeInit: this.beforeInit,
      afterInit: this.afterInit,
      beforeLoadSchema: this.beforeLoadSchema,
      afterLoadSchema: this.afterLoadSchema,
      beforeGetAll: this.beforeGetAll,
      afterGetAll: this.afterGetAll,
      beforeUpsert: this.beforeUpsert,
      afterUpsert: this.afterUpsert,
      beforeDelete: this.beforeDelete,
      afterDelete: this.afterDelete
    };
    this.processPayload(component, payload);
    hookEvent.setParam('payload', payload);
    hookEvent.fire();
  },
  processPayload: function(component, payload) {
    for (const hook in payload) {
      try {
        const func = payload[hook](component);
        if (typeof func !== 'undefined' && typeof func !== 'function') {
          throw 'returned non-function';
        }
        if (typeof func !== 'function') {
          delete payload[hook];
        } else {
          payload[hook] = func;
        }
      } catch (e) {
        console.log('Failed to add payload ' + hook + ' to hooks. The implementation did not return a funcion. ' +
          'All before/after hooks should either return a function which is executed when the pipeline event fires, or do nothing');
      }
    }
  },

  beforeInit: function(component) {},
  afterInit: function(component) {},
  beforeLoadSchema: function(component) {},
  afterLoadSchema: function(component) {},
  beforeGetAll: function(component) {},
  afterGetAll: function(component) {},
  beforeUpsert: function(component) {},
  afterUpsert: function(component) {},
  beforeDelete: function(component) {},
  afterDelete: function(component) {}
})