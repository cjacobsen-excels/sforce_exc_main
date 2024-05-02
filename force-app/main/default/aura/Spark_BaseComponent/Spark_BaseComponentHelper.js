({

  /*****************************************************************************
   * CRUD API
   *****************************************************************************/
  initialize: function(component) {
    component = component;
    this.beforeInit(component);
    this.setupDataProcessors(component);
    this.afterInit(component);
    this.loadSchema(component);
  },

  /**
   * @description loads the schema from Dynamic_Config__mdt based on the
   * schemaName attribute. Sets the loading status from 'initializing' to 
   * 'loading' after the schema is loaded. 
   **/
  loadSchema: function(component) {
    this.beforeLoadSchema(component);
    const schemaName = component.get('v.schemaName');
    if (schemaName) {
      this.standardizeCallout(component, 'loadSchema', { schemaName: schemaName }, true).then((data) => {
        component.set('v.schemaData', this.afterLoadSchema(component, data));
      }).catch(e => {});
    } else {
      const schemaData = component.get('v.schemaData');
      if (schemaData) {
        this.afterLoadSchema(component, schemaData);
      }
    }
  },

  /**
   * @description Uses the ViewModel to query records.
   **/
  getAll: function(component, viewModel, refresh) {
    if (!viewModel) viewModel = component.get('v.viewModel');
    if (refresh) {
      try {
        viewModel = this.beforeGetAll(component, false);
        viewModel.data.items = [];
      } catch (e) {}
    } else {
      this.beforeGetAll(component, true);
    }
    this.standardizeCallout(component, 'getAll', { viewModel: JSON.stringify(viewModel) }).then(data => {
      this.updateViewModel(component, data);
      this.afterGetAll(component);
    }).catch(e => {});
  },


  upsert: function(component) {
    const vm = this.beforeUpsert(component);
    this.standardizeCallout(component, 'upsertAll', { viewModel: JSON.stringify(vm) }).then(data => {
      this.updateViewModel(component, data);
      this.afterUpsert(component);
    }).catch(e => {});
  },

  deleteMarked: function(component) {
    const vm = this.beforeDelete(component);
    this.standardizeCallout(component, 'deleteAll', { viewModel: JSON.stringify(vm) }).then(data => {
      this.updateViewModel(component, data);
      this.afterDelete(component);
    }).catch(e => {});
  },

  rawQuery: function(component, queryParam) {
    let tempViewModel = { query: {} };
    if (typeof queryParam === 'string') {
      tempViewModel['query']['rawQuery'] = queryParam;
    } else if (typeof queryParam === 'object') {
      if (queryParam.hasOwnProperty('query') || queryParam.hasOwnProperty('queries')) {
        tempViewModel = queryParam;
      } else {
        tempViewModel['query'] = queryParam;
      }
    } else {
      this.throwError(component, 'Failed to parse the raw query');
    }

    const promise = this.standardizeCallout(component, 'getAll', { viewModel: JSON.stringify(tempViewModel) });
    promise.catch(err => {
      this.throwError(component, 'Failed to execute a query');
      console.log('Failed to execute raw query:', err, queryParam);
    });
    return promise;
  },

  /*****************************************************************************
   * CRUD data pipeline (before and after methods)
   *****************************************************************************/

  /**
   * @description Overridable method. Can be used to transform the function(component)'s
   * data before running onInit. Currently does nothing.
   **/
  beforeInit: function(component) {
    this.setAttributeProp(component, 'loadingStatus.loading', true);
    this.setAttributeProp(component, 'loadingStatus.refreshing', false);
    this.setAttributeProp(component, 'loadingStatus.schemaLoaded', false);
    this.setAttributeProp(component, 'loadingStatus.saving', false);
    this.setLoadingStatus(component, 'loading');
    this.runHooks(component, 'beforeInit');
  },


  /**
   * @description Overridable method. Can be used to transform the function(component)'s
   * data after running onInit. Currently does nothing.
   **/
  afterInit: function(component) {
    this.runHooks(component, 'afterInit');
  },


  /**
   * @description Overridable method. Can be used to transform the function(component)'s
   * data before the schema is loaded. Currently does nothing.
   **/
  beforeLoadSchema: function(component) {
    this.runHooks(component, 'beforeLoadSchema');
  },


  /**
   * @description Overridable method. Can be used to transform the function(component)'s
   * data after the schema is loaded or change how the default query is run.
   * Currently sets the ViewModel's query attribute and runs getAll.
   **/
  afterLoadSchema: function(component, data) {
    console.log(data);
    let schemaData;
    if (typeof data === 'string') {
      const dataParts = data.split('---');
      if (dataParts.length > 1) {
        //After data is recieved, we are going to render it
        this.initializeTemplateEngine(component);
        this.storeTemplates(component, data, dataParts);
        data = dataParts[0];
      }


      while (data.indexOf('{!v.') !== -1) {
        const index = data.indexOf('{!v.');
        const end = data.indexOf('}', index);
        const varName = data.substring(index + 4, end);
        data = data.replace('{!v.' + varName + '}', component.get('v.' + varName));
      }
      try {
        schemaData = JSON.parse(data);
        console.log('schema data:', schemaData);
        component.set('v.schemaData', schemaData);
      } catch (e) {
        this.throwError(component, 'Failed to parse schema');
        console.log('Failed to parse schema: ', data);
      }
    } else {
      schemaData = data;
    }
    this.setAttributeProp(component, 'loadingStatus.schemaLoaded', true);
    const vm = this.addQueryData(component, (schemaData.query || schemaData.queries));
    this.getAll(component, vm);
    this.runHooks(component, 'afterLoadSchema', [data]);
  },


  /**
   * @description Overridable method. Can be used to transform the function(component)'s
   * data before trying to get data.
   **/
  beforeGetAll: function(component, firstRun) {
    this.runHooks(component, 'beforeGetAll');
    if (!firstRun) {
      this.setLoadingStatus(component, 'saving');
      return this.doModelProcessing(component, 'TO_SERVER', false);
    }

  },


  /**
   * @description Overridable method. Can be used to transform the function(component)'s
   * data after getting data.
   **/
  afterGetAll: function(component) {
    this.runHooks(component, 'afterGetAll');
  },



  beforeUpsert: function(component) {
    this.setLoadingStatus(component, 'saving');
    this.runHooks(component, 'beforeUpsert');
    return this.doModelProcessing(component, 'TO_SERVER', false);
  },



  afterUpsert: function(component) {
    this.runHooks(component, 'afterUpsert');
    this.setLoadingStatus(component, 'loaded');
  },



  beforeDelete: function(component) {
    this.setLoadingStatus(component, 'saving');
    this.runHooks(component, 'beforeDelete');
    return this.doModelProcessing(component, 'TO_SERVER', false);
  },



  afterDelete: function(component) {
    this.runHooks(component, 'afterDelete');
    this.setLoadingStatus(component, 'loaded');
  },

  addHook: function(component, hookName, func) {
    let hooks = component.get('v.hooks');
    if (!hooks) hooks = {};
    if (!hooks[hookName]) {
      hooks[hookName] = [];
    }
    hooks[hookName].push(func);
    component.set('v.hooks', hooks);
  },

  addHooks: function(component, hooks) {
    for (const hook in hooks) {
      this.addHook(component, hook, hooks[hook]);
    }
  },

  runHooks: function(component, hookName, args) {
    let hooks = component.get('v.hooks');
    if (hooks && hooks[hookName]) {
      if (!args) args = [];
      args.unshift(component);
      for (const func of hooks[hookName]) {
        func.apply(this, args);
      }
    }
  },

  createHookComponent: function(component, compName, params) {
    $A.createComponent(compName, this.extend([{
      "viewModel": component.getReference('v.viewModel'),
      "schemaData": component.getReference('v.schemaData')
    }, params]), (comp, status, errorMessage) => {
      if (status === 'SUCCESS') {
        let body = component.get('v.body');
        body.push(comp);
        component.set('v.body', body);
      } else if (status === "INCOMPLETE") {
        console.log("No response from server or client is offline.")
          // Show offline error
      } else if (status === "ERROR") {
        console.log("Error: " + errorMessage);
        // Show error message
      }
    });
  },

  /*****************************************************************************
   * Internal data functions
   *****************************************************************************/
  standardizeCallout: function(component, func, params, raw) {
    var $this = this;
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.' + func);
      action.setParams(params);
      action.setCallback($this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          try {
            let data = response.getReturnValue();
            if (raw) {
              resolve(data);
            } else {
              data = JSON.parse(data);
              console.log('data:', data);
              if ($this.vmHasErrors(component, data)) {
                this.setLoadingStatus(component, 'error');
                reject(data);
              } else {
                resolve(data);
              }
            }
          } catch (e) {
            console.log(e);
            $this.throwError(component, e);
          }
        } else if (state === 'ERROR') {
          var errors = response.getError();
          var message = 'Communication with server failed';
          if (errors) {
            message += ': ' + errors[0];
          }
          $this.throwError(component, message);
          reject(response);
        }
      });
      $A.enqueueAction(action);
    }));
  },


  /**
   * @description Updates the viewModel.
   * @todo: Standardize how the current view model is updated with the new view Model
   **/
  updateViewModel: function(component, newViewModel) {
    try {
      const vm = this.doModelProcessing(component, 'FROM_SERVER', newViewModel);
      try {
        component.set('v.viewModel', vm);
        if (vm.data.items.length === 0) {
          this.setLoadingStatus(component, 'nodata');
        } else {
          this.setLoadingStatus(component, 'loaded');
        }
      } catch (e) {
        console.log('failed vm:', vm);
        this.throwError(component, 'Failed to parse the template with the given view model');
      }
    } catch (e) {
      this.throwError(component, 'An error occurred when processing the server\'s data and rendering the template.');
    }
  },


  /**
   * @description Checks the view model for standard messaging data and displays the
   * appropriate toast dialog for each given message.
   * @returns true if the promise should reject the response.
   **/
  throwError: function(component, error) {
    if (Object.keys(error).indexOf('statusText') !== -1) {
      const title = 'Error ' + error.status + ': ' + error.statusText;
      const message = error.body;
      this.showToast(component, title, message, 'error');
    } else if (typeof error === 'string') {
      this.showToast(component, 'Error', error, 'error');
    } else if (Object.keys(error).indexOf('message')) {
      this.showToast(component, error.title, error.message, 'error', error);
    }
  },


  /**
   * @description Checks the view model for standard messaging data and displays the
   * appropriate toast dialog for each given message.
   * @returns true if the promise should reject the response.
   **/
  vmHasErrors: function(component, viewModel) {
    try {
      const info = viewModel.data.info;
      if (!viewModel.data.success && info.debug && info.debug.length > 0) {
        console.log(info.debug);
      }
      if (info.errorMessage && info.errorMessage.length > 0) {
        this.throwError(component, info.errorMessage);
        info.errorMessage = '';
        return !viewModel.data.success;
      }
      if (info.successMessage && info.successMessage.length > 0) {
        this.showToast(component, 'Success', info.successMessage, 'success');
        info.successMessage = '';
      } else if (info.saveResultsSuccesses > 0) {
        this.showToast(component, 'Save successful', info.saveResultsSuccesses + ' records successfully saved', 'success');
      }
      if (info.infoMessage && info.infoMessage.length > 0) {
        this.showToast(component, 'Notice:', info.infoMessage, 'info');
        info.infoMessage = '';
      } else if (info.deleteResultsSuccesses > 0) {
        this.showToast(component, 'Delete successful', info.deleteResultsSuccesses + ' records successfully deleted', 'info');
      }
    } catch (e) {}
    return false;
  },


  /**
   * @description Takes the query attribute from a schema and uses it to update
   * the viewModel. If the query attribute is a string, it will save the string
   * to the rawQuery attribute. Otherwise, it will use the raw attribute.
   * @param queryParam A string with the raw query or an object with the
   * parameterized query.
   **/
  addQueryData: function(component, queryParam) {
    let viewModel = component.get('v.viewModel');
    let recordId = component.get('v.recordId');
    const isMulti = (queryParam.hasOwnProperty('length') && typeof queryParam === 'object');

    if (!viewModel) viewModel = isMulti ? { queries: [] } : { query: { rawQuery: '' } };
    const query = (isMulti) ? 'queries' : 'query';
    if (typeof queryParam === 'string') {
      viewModel['query']['rawQuery'] = queryParam;
    } else if (typeof queryParam === 'object') {
      viewModel[query] = queryParam;
    } else {
      this.throwError(component, 'Failed to parse the query from the schema');
    }

    if (typeof recordId !== 'undefined' && recordId !== null) {
      if (isMulti) {
        for (let i = 0; i < viewModel[query].length; i++) {
          viewModel[query][i]['recordId'] = recordId;
        }
      } else {
        viewModel[query]['recordId'] = recordId;
      }
    }
    component.set('v.viewModel', viewModel);
    return viewModel;
  },


  /**
   * @description Given a field name or the alias used to refer to the field, returns the 
   * field describe information.
   * @param {String} fieldAlias 
   */
  getFieldDescribe: function(component, fieldAlias) {
    const fieldDescribes = component.get('v.viewModel').query.fieldDescribes;
    if (fieldDescribes.hasOwnProperty(fieldAlias)) return fieldDescribes[fieldAlias];
    fieldAlias = fieldAlias.toLowerCase();
    for (let key in fieldDescribes) {
      if ((key.toLowerCase() === fieldAlias) ||
        (fieldDescribes[key].aliasName !== null &&
          fieldDescribes[key].aliasName.toLowerCase() === fieldAlias)) {
        return fieldDescribes[key];
      }
    }
    return null;
  },


  setAttributeProp: function(component, attributePath, value) {
    let path = attributePath.split('.');
    let attribute = component.get('v.' + path[0]);
    if (!attribute) attribute = {};
    //@todo: use path walking
    attribute[path[1]] = value;
    component.set('v.' + path[0], attribute);
  },


  /*****************************************************************************
   * Data transformations
   *****************************************************************************/
  setupDataProcessors: function(component) {
    this.addDataProcessor(component, 'TO_SERVER', this.stripNewIds);
    this.addDataProcessor(component, 'TO_SERVER', this.convertItemPropertiesToString);
    this.addDataProcessor(component, 'TO_SERVER', this.untransformAliases);
    this.addDataProcessor(component, 'FROM_SERVER', this.convertItemPropertiesToObject);
    this.addDataProcessor(component, 'FROM_SERVER', this.resetModifiedFlag);
    this.addDataProcessor(component, 'FROM_SERVER', this.transformAliases);
  },


  addDataProcessor: function(component, processName, func) {
    let dataProcessors = component.get('v.dataProcessors');
    if (!dataProcessors) {
      dataProcessors = {};
    }
    if (!dataProcessors[processName]) {
      dataProcessors[processName] = [];
    }
    dataProcessors[processName].push(func);
    component.set('v.dataProcessors', dataProcessors);
  },



  doModelProcessing: function(component, processName, vm) {
    let dataProcessors = component.get('v.dataProcessors');
    if (!dataProcessors || !dataProcessors[processName])
      return;

    const processors = dataProcessors[processName];
    if (!vm) {
      vm = JSON.parse(JSON.stringify(component.get('v.viewModel')));
    }

    for (let i = 0; i < vm.data.items.length; i++) {
      const item = vm.data.items[i];
      for (let k = 0; k < processors.length; k++) {
        processors[k](item);
      }
      for (let j = 0; j < item.children.length; j++) {
        for (let k = 0; k < processors.length; k++) {
          processors[k](item.children[j]);
        }
      }
    }

    return vm;
  },


  convertItemPropertiesToString: function(item, parentItem) {
    if (item.hasOwnProperty('properties') && typeof item.properties === 'object') {
      item.properties = JSON.stringify(item.properties);
    }
  },



  stripNewIds: function(item, parentItem) {
    if (item.value.Id && item.value.Id.indexOf('new-') !== -1) {
      item.properties['oldId'] = item.value.Id;
      delete item.value.Id;
    }
  },



  convertItemPropertiesToObject: function(item, parentItem) {
    if (item.hasOwnProperty('properties') && typeof item.properties === 'string' && item.properties !== null) {
      item.properties = JSON.parse(item.properties);
    }
  },



  resetModifiedFlag: function(item, parentItem) {
    item.modified = false;
  },



  transformAliases: function(item, parentItem) {
    const aliases = (parentItem) ? this.childAliases : this.parentAliases;
    if (!aliases)
      return;

    for (let i = 0; i < aliases.length; i++) {
      const oldKey = aliases[i].oldKey;
      if (item.value.hasOwnProperty(oldKey)) {
        item.value[aliases[i].newKey] = item.value[oldKey];
        delete item.value[oldKey];
      }
    }
  },



  untransformAliases: function(item, parentItem) {
    const aliases = (parentItem) ? this.childAliases : this.parentAliases;
    if (!aliases)
      return;

    for (let i = 0; i < aliases.length; i++) {
      const newKey = aliases[i].newKey;
      if (item.value.hasOwnProperty(newKey)) {
        item.value[aliases[i].oldKey] = item.value[newKey];
        delete item.value[newKey];
      }
    }
  },


  splitRecordsByType: function(component) {
    let vm = component.get('v.viewModel');
    let types = []
    for (let record of vm.data.items) {
      let recordType = record.value.attributes.type.toLowerCase();
      if (types.indexOf(recordType) === -1) {
        types.push(recordType);
        vm.data[recordType] = [];
      }
      vm.data[recordType].push(record);
    }
    vm.data.items = [];
    component.set('v.viewModel', vm);
  },

  combineSplitRecords: function(component) {
    let vm = component.get('v.viewModel');
    let types = [];
    for (let key of Object.keys(vm.data)) {
      if (key.indexOf('__c') !== -1) {
        types.push(key);
      }
    }
    for (let key of types) {
      for (let record of vm.data[key]) {
        vm.data.items.push(record);
      }
      vm.data[key] = undefined;
    }
    return vm;
  },

  renderTemplates: function(component) {
    let nodes = document.getElementsByClassName('template');
    const engine = this.library(component, 'templateEngine').getEngine();
    console.log('renderTemplate:', component.getGlobalId());
    try {
      engine.applyTemplates(
        nodes,
        component.get('v.templates'),
        component.get('v.viewModel'),
        component.getGlobalId()
      );
    } catch (e) {
      console.log(e);
      const vm = component.get('v.viewModel');
      console.log(vm);
      console.log(component.getGlobalId());
      console.log(JSON.stringify(component.get('v.templates')));
      this.throwError(component, 'Template Parsing Error.');
    }
  },


  renderTemplate: function(component, templateName) {
    let node = document.getElementById(component.getGlobalId() + '_' + templateName);
    const templates = component.get('v.templates');
    if (!node)
      this.throwError(component, 'Could not find a place to insert the template');
    if (!templates[templateName])
      this.throwError(component, 'Could not find a template named "' + templateName + '"');

    node.innerHTML = this.render(component, templates[templateName]);
  },

  render: function(component, template, data) {
    const engine = this.library(component, 'templateEngine').getEngine();
    if (!data) data = component.get('v.viewModel');
    return engine.render(template, data);
  },


  /*****************************************************************************
   * Dependency Injection
   *****************************************************************************/
  library: function(component, libraryName) {
    if (!this.libraries) this.libraries = {};
    if (!this.libraries[libraryName]) {
      this.libraries[libraryName] = component.find(libraryName);
    }
    return this.libraries[libraryName];
  },

  /*****************************************************************************
   * UI Tools
   *****************************************************************************/
  showToast: function(component, title, message, type, options) {
    if (typeof options !== 'object') {
      options = {};
    }
    if (typeof type === 'undefined') {
      type = 'info';
    }
    options['title'] = title;
    options['message'] = message;
    options['type'] = type;

    const event = $A.get("e.force:showToast");
    event.setParams(options);
    event.fire();
  },

  storeTemplates: function(component, data, dataParts) {
    var templates = component.get('v.templates');
    if (!templates) templates = {};
    for (let i = 1; i < dataParts.length; i++) {
      const index = dataParts[i].indexOf(':');
      if (index !== -1) {
        const name = dataParts[i].substring(0, index).replace(/\s/g, '');
        templates[name] = dataParts[i].substring(index + 1);
      } else {
        this.throwError(component, 'Failed to parse template in config file');
      }
    }
    component.set('v.templates', templates);
  },

  setLoadingStatus: function(component, status) {
    let loadingStatus = component.get('v.loadingStatus');
    let statefulClasses = 'stateful';
    let statefulElement = component.getConcreteComponent();
    if (typeof statefulElement !== 'undefined' && statefulElement !== null) {
      statefulElement = statefulElement.getElement();
      if (statefulElement !== null && typeof statefulElement.querySelector === 'function') {
        if (statefulElement.className.indexOf(statefulClasses) === -1) {
          statefulElement = statefulElement.querySelector('.' + statefulClasses);
        }

        statefulClasses = statefulElement.className;
        statefulClasses = statefulClasses
          .replace(' saving', '')
          .replace(' loading', '')
          .replace(' nodata', '')
          .replace(' error', '')
          .replace(' loaded', '');
      }
    }
    console.log('element', statefulElement);
    if (loadingStatus === null) loadingStatus = {};

    switch (status) {
      case 'saving':
        loadingStatus.saving = true;
        statefulClasses += ' saving';
      case 'loading':
        statefulClasses += ' loading';
        loadingStatus.loading = true;
        break;
      case 'nodata':
        statefulClasses += ' nodata';
        loadingStatus.noData = true;
      case 'loaded':
        statefulClasses += ' loaded';
        loadingStatus.loading = false;
        loadingStatus.saving = false;
        break;
      case 'error':
        statefulClasses += ' error';
        loadingStatus.loading = false;
        loadingStatus.error = true;
        break;
    }

    component.set('v.loadingStatus', loadingStatus);
    if (statefulElement) {
      statefulElement.className = statefulClasses;
    }
  },

  /**
   * Adds hooks to re-render templates after data comes back from Salesforce and loads 
   * the templateEngine in memory.
   */
  initializeTemplateEngine: function(component) {
    const renderTemplate = () => {
      this.renderTemplates(component);
    }

    this.addHook(component, 'afterGetAll', renderTemplate);
    this.addHook(component, 'afterUpsert', renderTemplate);
    this.addHook(component, 'afterDelete', renderTemplate);
  },

  /*****************************************************************************
   * Utility Functions
   *****************************************************************************/
  /**
   * 
   * @param {object} scope 
   * @param {array} pathArray - An array of relative fields to walk through. 
   */
  walkPath: function(component, scope, pathArray) {
    const searchKey = pathArray.splice(0, 1)[0].toLowerCase();
    const nextScope = scope[Object.keys(scope).find(key => key.toLowerCase() === searchKey)];
    if (pathArray.length === 0) {
      return nextScope;
    } else {
      return this.walkPath(component, nextScope, pathArray);
    }
  },

  /**
   * Given a relative path, returns the data
   * @param {object} variable - The data (i.e. a view model item)
   * @param {string} path - The field's relative path (i.e "Account.Owner.FirstName")
   * @returns {any} - the value of the item's field
   */
  getValueFromPath: function(component, variable, path) {
    try {
      return this.walkPath(component, variable, path.split('.'));
    } catch (e) {
      return null;
    }
  },

  /**
   * Updates a variable given the relative path to update
   * @param {object} variable - The data (i.e. a view model item)
   * @param {string} path - The field's relative path (i.e "Account.Owner.FirstName")
   * @param {any} newValue - The new value
   */
  setValueFromPath: function(component, variable, path, newValue) {
    try {
      path = path.split('.');
      let lastPath = path.pop();
      let pointer = variable;
      if (path.length > 0) {
        pointer = this.walkPath(component, variable, path);
      }
      pointer[lastPath] = newValue;
      return true;
    } catch (e) {}
    return false;
  },

  /**
   * Returns ID that can be used temporarily for a new object's ID field
   */
  newId: function(component) {
    return 'new-' + ('' + new Date().getTime()).substring(7);
  },

  /** 
   * Given a list of objects, merges the properties. For deep merges
   * set the first argument to true.
   * 
   * @example extend(obj1, obj2, obj3, ...);
   * @example extend(true, record, oldRecord);
   */
  extend: function(component, args) {
    let extended = {};
    let deep = false;
    let i = 0;
    let length = args.length;

    // Check if a deep merge
    if (Object.prototype.toString.call(args[0]) === '[object Boolean]') {
      deep = args[0];
      i++;
    }

    // Merge the object into the extended object
    const merge = obj => {
      for (const prop in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, prop)) {
          // If deep merge and property is an object, merge properties
          if (deep && Object.prototype.toString.call(obj[prop]) === '[object Object]') {
            extended[prop] = this.extend(component, [true, extended[prop], obj[prop]]);
          } else {
            extended[prop] = obj[prop];
          }
        }
      }
    };

    // Loop through each object and conduct a merge
    for (; i < length; i++) {
      let obj = args[i];
      merge(obj);
    }

    return extended;
  },


  /**
   * Extends a viewModel object. For data records, uses the Id field to match the record and extend.
   * @todo: Add in logic to replace temp ids with concrete Ids when extending post-upsert.
   * @todo: Potentially check if viewModel has errors and clear errors after emitting messages.
   * 
   * @param {Object} mergeVm The viewModel to extend the current view model with.
   * @param {Object} viewModel (Optional) the view model to extend. If ignored, this will get the 
   *        current view model and overwrite it after extension.
   */
  extendViewModel: function(component, mergeVm, viewModel) {
    let handledProps = [];
    let saveAfterExtend = false;
    if (!viewModel) {
      saveAfterExtend = true;
      viewModel = component.get('v.viewModel');
    }
    for (const prop in viewModel) {
      handledProps.push(prop);
      if (mergeVm[prop]) {
        // If we're talking about the data property, we need to handle the items with special logic
        if (prop.toLowerCase() === 'data') {
          for (const dataProp in viewModel.data) { // Iterate over the data prop's properties. If it's not items, just extend.
            if (dataProp.toLowerCase() !== 'items' && mergeVm.data[dataProp]) {
              viewModel.data[dataProp] = this.extend(component, [true, viewModel.data[dataProp], mergeVm.data[dataProp]]);
            } else if (dataProp.toLowerCase() === 'items' && mergeVm.data.items) { // It's the items, use special logic to extend
              viewModel.data.items = this.extendItems(component, viewModel.data.items, mergeVm.data.items);
            }
          }
        } else { // It's not the data prop, just extend it.
          viewModel[prop] = this.extend(component, [true, viewModel[prop], mergeVm[prop]]);
        }
      }
    }

    for (const prop in mergeVm) {
      if (handledProps.indexOf(prop) === -1) { // The main viewModel is missing this property, let's throw it in
        viewModel[prop] = mergeVm[prop];
      }
    }
    if (saveAfterExtend) {
      console.log('new view model', viewModel);
      component.set('v.viewModel', viewModel);
    }
    return viewModel;
  },

  extendItems: function(component, items, newItems) {
    let idMap = {};
    let i = 0;
    for (const item of items) {
      idMap[item.value.Id] = i++;
    }
    for (const item of newItems) {
      if (idMap.hasOwnProperty(item.value.Id)) {
        const originalItem = items[idMap[item.value.Id]];
        if (originalItem.children && item.children) {
          originalItem.children = this.extendItems(component, originalItem.children, item.children);
          delete item.children;
        }
        this.extend(component, [true, originalItem, item]);
      } else {
        items.push(item);
      }
    }
    return items;
  },


  /**
   * When you run component.find('AuraIdHere') it will only return a result if the component exists in
   * the component you are searching from. That is to say, if a 'AuraIdHere' is in a parent component,
   * it won't be returned by component.find. This will search the current component and all parent
   * components until it is found or until it is at the base component.
   */
  findComponent: function(component, query) {
    while (component !== null && typeof component !== 'undefined') {
      let result = component.find(query);
      if (typeof result === 'undefined') {
        component = component.getSuper();
      } else {
        return result;
      }
    }
    return null;
  },


  /* @todo: Remove from base component and put inside of an injectable library */
  search: function(component, query) {
    var helper = this;
    return new Promise($A.getCallback(function(resolve, reject) {
      //@todo: Run the search query in salesforce if we don't have all records in memory
      var viewModel = component.get('v.viewModel');
      if (viewModel.data.hasOwnProperty('allItems')) {
        viewModel.data.items = viewModel.data.allItems;
      }
      viewModel.data.allItems = JSON.parse(JSON.stringify(viewModel.data.items));
      Object.keys(viewModel.data.items[0].value);
      viewModel.data.items = [];
      query = query.toLowerCase();
      for (var i = 0; i < viewModel.data.allItems.length; i++) {
        var item = viewModel.data.allItems[i].value;
        if (helper.doSearch(query, item)) {
          viewModel.data.items.push(viewModel.data.allItems[i]);
        }
      }
      component.set('v.viewModel', viewModel);
      resolve(viewModel);
    }));
  },

  doSearch: function(query, item) {
    var keys = Object.keys(item);
    for (var i = 0; i < keys.length; i++) {
      var val = item[keys[i]];
      if (typeof val === 'object' && this.doSearch(query, val)) {
        return true;
      }
      if (typeof val.toLowerCase === 'function') {
        val = val.toLowerCase();
      }
      if (typeof val.indexOf === 'function' && val.indexOf(query) !== -1) {
        return true;
      } else if (val === query) {
        return true;
      }
    }
  },
  log: function(data) {
    console.log(JSON.parse(JSON.stringify(data)));
  }
})