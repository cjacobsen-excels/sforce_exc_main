({
  setupData: function(component) {
    this.addDefaultColumns(component);
    let joinCount = component.get('v.joinCount');
    joinCount++;
    if (joinCount > 1) {
      this.setupCheckboxes(component);
    }
    component.set('v.joinCount', joinCount);
  },
  afterSchemaSetup: function(component) {
    this.afterLoadSchemaHook(component);
    this.getJunctionData(component);
  },
  getJunctionData: function(component) {
    let schemaData = component.get('v.schemaData');
    if (typeof schemaData === 'undefined') {
      schemaData = component.get('v.schemaDataCopy');
    }
    if (typeof schemaData.junction === 'undefined') {
      this.throwError('Junction object not defined in Dynamic Config');
    }
    const recordId = component.get('v.recordId');
    schemaData.junction['recordId'] = recordId;
    const mapField = schemaData.junction.mapField;
    let query = JSON.parse(JSON.stringify(schemaData.junction));
    delete query.mapField;
    component.set('v.schemaDataCopy', schemaData);
    this.rawQuery(component, query).then((data) => {
      let checked = [];
      component.set('v.junctionData', data);
      for (let item of data.data.items) {
        checked.push(item.value[mapField]);
      }
      component.set('v.checked', checked);
      component.set('v.oldChecked', checked);
      let joinCount = component.get('v.joinCount');
      joinCount++;
      if (joinCount > 1) {
        this.setupCheckboxes(component);
      }
      component.set('v.joinCount', joinCount);
      component.set('v.changes', false);
      component.set('v.editMode', false);
    });
  },
  toggleEditMode: function(component) {
    let editMode = component.get('v.editMode');
    if (!editMode) {
      component.set('v.editMode', true);
    } else {
      if (component.get('v.changes') && !confirm('Are you sure you want to undo your changes?')) {
        this.toggleEditButton(component);
        return;
      }
      component.set('v.editMode', false);
      component.set('v.changes', false);
    }
  },
  setupCheckboxes: function(component) {
    let data = component.get('v.data');
    let checked = component.get('v.checked');
    for (var i = 0; i < data.length; i++) {
      let id = (typeof data[i][0] === 'object') ? data[i][0][1] : data[i][0];
      let isChecked = checked.indexOf(id) !== -1
      data[i][0] = [isChecked, id];
    }
    component.set('v.data', data);
  },
  toggleEditButton: function(component) {
    let header = component.getSuper().find('header');
    let getHelper = header.get('c.getHelper');
    getHelper.setCallback(this, res => {
      let helper = res.getReturnValue();
      helper.setButtonState(header, 0, false);
    });
    $A.enqueueAction(getHelper);
  },
  getJunctionDataChanges: function(component) {
    let checked = component.get('v.checked');
    let oldChecked = component.get('v.oldChecked');
    let junctionData = component.get('v.junctionData');
    // Why save in a copy? Salesforce's developers are incompetent.
    let schemaData = component.get('v.schemaDataCopy');
    const mapField = schemaData.junction.mapField;
    const recordId = component.get('v.recordId');
    let fromField = schemaData.junction.whereClause.replace(/ /mg, '').replace('=', '').replace("'$RECORDID'", '');
    let toCreate = [];

    for (let current of checked) {
      let index = oldChecked.indexOf(current)
      if (index === -1) {
        toCreate.push(current);
      } else {
        oldChecked.splice(index, 1);
      }
    }
    //Anything left in oldChecked needs to be deleted

    for (let i = 0; i < junctionData.data.items.length; i++) {
      let item = junctionData.data.items[i];
      if (oldChecked.indexOf(item.value[mapField]) !== -1) {
        item.toDelete = true;
      }
    }

    for (let newJunctionId of toCreate) {
      let data = {
        modified: true,
        children: [],
        toDelete: false,
        properties: {},
        value: {
          Id: 'new-' + ('' + new Date().getTime()).substring(7),
          attributes: {
            type: schemaData.junction.sObjectType
          }
        }
      };
      data.value[fromField] = recordId;
      data.value[mapField] = newJunctionId;
      junctionData.data.items.push(data);
    }
    component.set('v.oldChecked', checked);
    return junctionData;
  },
  upsertJunctionData: function(component, junctionData) {
    this.standardizeCallout(component, 'upsertAll', { viewModel: JSON.stringify(junctionData) }).then(data => {
      const vm = this.doModelProcessing(component, 'FROM_SERVER', junctionData);
      this.getJunctionData(component);
    });
  }

  /**
   * @todo: 
   * - Loading State
   */
})