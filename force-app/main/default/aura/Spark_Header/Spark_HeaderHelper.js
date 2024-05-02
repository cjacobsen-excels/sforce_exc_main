({
  afterLoadSchema: function(component) {
    return (parentComponent) => {
      component.set('v.schemaData', parentComponent.get('v.schemaData'));
      component.set('v.parentComponent', parentComponent);
    }
  },
  onSearch: function(component, query) {
    let parentComponent = component.get('v.parentComponent');
    let getHelper = parentComponent.get('c.getHelper');
    getHelper.setCallback(this, res => {
      let helper = res.getReturnValue();
      helper.search(parentComponent, query);
    });
    $A.enqueueAction(getHelper);
  },
  setButtonState: function(component, index, value) {
    let schemaData = component.get('v.schemaData');
    schemaData.header.actions[index].active = value;
    component.set('v.schemaData', schemaData);
  }

})