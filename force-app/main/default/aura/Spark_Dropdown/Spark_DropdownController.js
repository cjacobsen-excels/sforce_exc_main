({
    selectItem: function(component, event, helper) {
      let node = event.target;
      while (node !== null && (!node.dataset || !node.dataset['i'])) {
        node = node.parentElement;
      }
      const i = node.dataset['i'];
      const item = component.get('v.options')[i];
      let componentEvent = component.getEvent('componentEvent');
      componentEvent.setParam('data', item);
      componentEvent.setParam('type', 'dropdown_select');
      componentEvent.fire();
      console.log('item select end');
    },
    onItemHover: function(component, event, helper) {
      let node = event.target;
      while (node !== null && (!node.dataset || !node.dataset['i'])) {
        node = node.parentElement;
      }
      const i = parseInt(node.dataset['i'], 10);
      component.set('v.pointerIndex', i);
    },
    onEnterKey: function(component, event, helper) {
      const i = component.get('v.pointerIndex');
      const item = component.get('v.options')[i];
      let componentEvent = component.getEvent('componentEvent');
      componentEvent.setParam('data', item);
      componentEvent.setParam('type', 'dropdown_select');
      componentEvent.fire();
    },
    onArrowPress: function(component, event, helper) {
      const i = component.get('v.pointerIndex');
      const element = document.getElementById(component.getGlobalId() + '_' + i);
      element.scrollIntoView({
        block: 'nearest'
      });
    }
  })