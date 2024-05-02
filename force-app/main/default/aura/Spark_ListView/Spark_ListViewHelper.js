({
  addDefaultColumns: function(component) {
    let config = component.get('v.config');
    let vmQuery = component.get('v.viewModel').query;
    let columns = [];
    let fdList = {};
    if (config === null) {
      config = {};
    }

    if (typeof config.columns !== 'object') {
      config.columns = vmQuery.fields.filter((val, index, arr) => {
        return val !== 'Id';
      });
    }



    for (let i = 0; i < config.columns.length; i++) {
      let column = config.columns[i];
      if (typeof column === 'string') {
        column = { field: column };
      }

      const fieldDescribe = this.getFieldDescribe(component, column.field);
      fdList[column.field] = fieldDescribe;
      columns.push(column.field);
      if (!column.hasOwnProperty('label'))
        column.label = fieldDescribe.label;

      if (!column.hasOwnProperty('sortable'))
        column.sortable = config.sortable ? config.sortable : false;

      if (!column.hasOwnProperty('editable'))
        column.editable = config.editable ? config.editable : false;

      if (!column.hasOwnProperty('type'))
        column.type = this.defaultColumnType(component, fieldDescribe);

      if (!column.hasOwnProperty('isHTML'))
        column.isHTML = false;

      if (!column.hasOwnProperty('actions'))
        column.actions = [];

      if (!column.hasOwnProperty('component'))
        column.component = '';
      config.columns[i] = column;
    }
    component.set('v.config', config);
    console.log('list config:', JSON.stringify(config));
    let allData = [];
    for (let item of component.get('v.viewModel').data.items) {
      let dataSet = [];
      for (let column of columns) {
        dataSet.push(this.processData(
          this.getValueFromPath(component, item.value, column),
          fdList[column]));
      }
      allData.push(dataSet);
    }
    component.set('v.data', allData);
  },

  processData: function(rawValue, fieldDescribe) {
    //@todo: handle special values
    if (typeof rawValue === 'undefined' || rawValue === null) {
      return '';
    }
    if (fieldDescribe.type === 'ADDRESS') {
      return rawValue.street + ' ' + rawValue.city + ', ' + rawValue.state;
    }
    return rawValue;
  },




  /**
   * We need to decide between using the standard "List" definition,
   * in the schema, using an alternate name when pulling from the schema
   * or to use an object injected into the list from the attributes
   */
  afterLoadSchemaHook: function(component) {
    let customConfig = component.get('v.customConfig');
    try {
      if (typeof customConfig !== 'undefined' && customConfig !== null && customConfig === '') {
        if (customConfig.indexOf('{') !== -1) {
          component.set('v.config', JSON.parse(customConfig));
        } else {
          const schemaData = component.get('v.schemaData');
          component.set('v.config', schemaData[customConfig]);
        }
        return;
      }
    } catch (e) {
      console.log('failed to set custom config on hook component');
    }
    const schemaData = component.get('v.schemaData');
    if (schemaData === null || typeof schemaData.list === 'undefined') {
      this.throwError('Failed to load config from schemaData');
    }
    component.set('v.config', schemaData.list);

  },
  defaultColumnType: function(component, fieldDescribe) {
    if (fieldDescribe.type === 'ADDRESS') {
      return 'Address';
    }
    return 'String';
  }
})