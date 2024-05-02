/**
 * @author Ed Montalbano
 * @date 11-20-2019
 *
 * @group API
 *
 * @description This is the data access layer for the API. It handles generating
 * the query, getting the data, upserting / deleting data, and preparing the
 * view model which is sent back to the lightning component.
 * v1 - Initial build. Get, Upsert, Search, and get field describe
 * v2 - No longer statically referenced. Aliasing enabled on queries. Queries now
 *      run through simple lexer for advanced queries.
 * v2.1 - Enhanced the dynamic query functions
**/
global class SO_DAL {
  /*****************************************************************************
   * globally exposed interfaces
   ****************************************************************************/
   
  
  /*****************************************************************************
   * @description Uses the query attribute of the SO_ViewModel to generate a
   * SOQL query, runs the query and inserts the returned records into the view
   * model. This method checks object and field security and will attempt to
   * utilize a Standard Set Controller to control pagination. Before querying,
   * beforeGet transformations will be run on the view model. After querying,
   * afterGet transformations will be run on the view model.
   * @param model an instance of the SO_ViewModel.
   * @param withSharing Flag to decide if sharing rules should be applied.
   * @return SO_ViewModel after querying Salesforce and adding records to the
   * view model.
  **/
  global SO_ViewModel getAll(SO_ViewModel model, Boolean withSharing) {
    try {
      beforeGet(model, withSharing);

      model.data.items = new SO_ViewModel.sObjectListItem[]{};
      if (model.queries != null) {
        for (SO_ViewModel.Query query : model.queries) {
          runQuery(model, query, withSharing, false);
        }
      } else {
        SO_ViewModel.Query qModel = model.query;
        runQuery(model, qModel, withSharing, false);
      }
      
      afterGet(model, withSharing);
      
      // @todo: Analyze common exceptions and give better error handling information
    } catch (Exception e) {
      model.data.success = false;
      model.data.info.errorMessage = 'An unexpected error occurred.';
      model.data.info.debug = e.getMessage();
      System.debug(e);
      System.debug(e.getMessage());
    }
    return model;
  }
  
  
  /*****************************************************************************
   * @description Uses the data items attribute of the SO_ViewModel to upsert
   * the records in data.
   * @param model an instance of the SO_ViewModel.
   * @param modifiedOnly Flag to decide if this should upsert all records or 
   * only the flagged records.
   * @return SO_ViewModel after attempting to delete the records.
  **/
  global SO_ViewModel upsertAll(SO_ViewModel model, Boolean modifiedOnly) {
    List<sObject> toInsert = new List<sObject>();
    List<sObject> toUpdate = new List<sObject>();
    List<sObject> toDelete = new List<sObject>();
    List<Integer> iToRemove = new List<Integer>();
    List<String> jToRemove = new List<String>();
    Integer i = 0;
    for (SO_ViewModel.sObjectListItem li : model.data.items) {
      if (li.children.size() > 0) {
        Integer j = 0;
        for (SO_ViewModel.sObjectListItem liChild : li.children) {
          if (liChild.toDelete) {
            toDelete.add(liChild.value);
            jToRemove.add( String.valueOf(i) + ';' + String.valueOf(j));
          } else if (liChild.modified || !modifiedOnly) {
            if (liChild.value.Id == null){ 
              toInsert.add(liChild.value);
            } else {
              toUpdate.add(liChild.value);
            }     
          }
          j++;
        }
      }

      if (li.modified || li.toDelete || !modifiedOnly) {
        if (li.toDelete) {
          if (li.value.Id != null) {
            toDelete.add(li.value);
            iToRemove.add(i);
          }
        } else if (li.value.Id == null){ 
          toInsert.add(li.value);
        } else {
          toUpdate.add(li.value);
        }          
      }
      i++;
    }
    
    Boolean success = true;
    Integer successCnt = 0;
    Integer deleteCnt = 0;
    Integer errorCnt = 0;
    List<String> errorMessages = new List<String>();
    List<Database.SaveResult> insertResults = Database.insert(toInsert, false);
    List<Database.SaveResult> updateResults = Database.update(toUpdate, false);
    List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    if (toDelete.size() > 0) {
      for (Integer k = iToRemove.size()-1; k>=0; k--) {
        model.data.items.remove(iToRemove[k]);
      }
      for (Integer k = jToRemove.size()-1; k>=0; k--) {
        List<String> split = jToRemove[k].split(';');
        i = Integer.valueOf(split[0]);
        Integer j = Integer.valueOf(split[1]);
        model.data.items[i].children.remove(j);
      }
      List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
      for (Database.DeleteResult dr : deleteResults) {
        if (!dr.success) {
          success = false;
          errorCnt++;
          for (Database.Error err : dr.errors) {
            errorMessages.add(err.message);
          }
        } else {
          deleteCnt++;
        }
      }
      model.data.info.deleteResults = deleteResults;
      model.data.info.deleteResultSuccesses = deleteCnt;
      model.data.info.deleteResultErrors = errorCnt;
      model.data.info.deleteResultErrorMessages = errorMessages;
      errorMessages = new List<String>();
    }
    saveResults.addAll(insertResults);
    saveResults.addAll(updateResults);    
    
    for (Database.SaveResult sr : saveResults) {
      if (!sr.success) {
        success = false;
        errorCnt++;
        for (Database.Error err : sr.errors) {
          errorMessages.add(err.message);
        }
      } else {
        successCnt++;
      }
    }
    
    model.data.success = success;
    model.data.info.saveResults = saveResults;
    model.data.info.saveResultSuccesses = successCnt;
    model.data.info.saveResultErrors = errorCnt;
    model.data.info.saveResultErrorMessages = errorMessages;
    
    return model;
  }  
  
  
  /*****************************************************************************
   * @description Uses the data items attribute of the SO_ViewModel to delete
   * the records in data.
   * @param model an instance of the SO_ViewModel.
   * @param markedOnly Flag to decide if this should upsert all records or 
   * only the flagged records.
   * @return SO_ViewModel after attempting to delete the records.
  **/
  global SO_ViewModel deleteAll(SO_ViewModel model, Boolean markedOnly) {
    List<sObject> toDelete = new List<sObject>();
    
    for (SO_ViewModel.sObjectListItem li : model.data.items) {  
      if (li.children.size() > 0) {
        for (SO_ViewModel.sObjectListItem liChild : li.children) {
          if (liChild.toDelete || !markedOnly) {
            toDelete.add(liChild.value);
          }
        }
      }

      if (li.toDelete || !markedOnly) {
        toDelete.add(li.value);
      }
    }
    
    
    Boolean success = true;
    Integer successCnt = 0;
    Integer errorCnt = 0;
    List<String> errorMessages = new List<String>();
    List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
    
    
    for (Database.DeleteResult dr : deleteResults) {
      if (!dr.success) {
        success = false;
        errorCnt++;
        for (Database.Error err : dr.errors) {
          errorMessages.add(err.message);
        }
      } else {
        successCnt++;
      }
    }
    
    model.data.success = success;
    model.data.info.deleteResults = deleteResults;
    model.data.info.deleteResultSuccesses = successCnt;
    model.data.info.deleteResultErrors = errorCnt;
    model.data.info.deleteResultErrorMessages = errorMessages;
    
    return model;
  }


  /*****************************************************************************
   * @description Uses SOSL to search all fields for a query
   * @param sObjectType the sObject type to search.
   * @param query the string to search against the database.
   * @return SO_ViewModel after attempting to delete the records.
  **/
  global List<Map<String, Object>> searchAll(String sObjectType, String query, String returnFields) {
    returnFields = String.escapeSingleQuotes(returnFields.deleteWhitespace());
    query = String.escapeSingleQuotes(query);
    sObjectType = String.escapeSingleQuotes(sObjectType);
    String q = 'FIND \'*'+query+'*\' IN ALL FIELDS RETURNING ' + sObjectType + '('+returnFields+') WITH SNIPPET LIMIT 25';
    Search.SearchResults results = Search.find(q);
    List<String> fields = returnFields.split(',');
    List<Map<String, Object>> response = new List<Map<String, Object>>();
    for (Search.SearchResult result : results.get(sObjectType) ) {
      SObject o = result.getSObject();
      Map<String, Object> obj = new Map<String, Object>();
      for (String field : fields) {
        obj.put(field, o.get(field));
      }
      obj.put('snippet', result.getSnippet());
      response.add(obj);
    }
    return response;
  }
    
  
  /*****************************************************************************
   * internal methods section
   ****************************************************************************/
   
   
  /*****************************************************************************
   * @description Currently does nothing. Can be overridden to transform the
   * view model before the query has run.
   * @param model an instance of the SO_ViewModel.
   * @param withSharing Flag to decide if sharing rules should be applied.
   * @return SO_ViewModel after performing a transformation on the model.
  **/
  public void beforeGet(SO_ViewModel model, Boolean withSharing) { }
  
  
  /*****************************************************************************
   * @description Currently does nothing. Can be overridden to transform the
   * view model after the query has run and records have been inserted.
   * @param model an instance of the SO_ViewModel.
   * @param withSharing Flag to decide if sharing rules should be applied.
   * @return SO_ViewModel after performing a transformation on the model.
  **/
  public void afterGet(SO_ViewModel model, Boolean withSharing) { }
  
   
  /*****************************************************************************
   * @description If the Query component is using a raw query, this method will
   * extract the fields and sObjectType for 
   * @param qModel an instance of the SO_ViewModel's Query object.
   * @return SO_ViewModel after performing a transformation on the model.
  **/
  public void extractModelFromRawQuery(SO_ViewModel.Query qModel) {
    System.debug(qModel);
    System.debug(qModel.rawQuery);
    String tempQuery = qModel.rawQuery.toLowerCase().replaceAll('[ ]+', ' ');
    qModel.fields = tempQuery.split(' from ')[0]
           .replace('select', '')
           .replace(' ','').split(',');
    qModel.sObjectType = tempQuery.split('from ')[1].split(' ')[0];
  }
  
  
  /*****************************************************************************
   * @description Checks the state of the view model to determine if the system
   * should use a set controller to get records, or if it has to use a raw query.
   * @param model an instance of the SO_ViewModel.
   * @return True if we can use a set controller for the query
  **/
  public Boolean canUseSetController(SO_ViewModel.Query qModel) {
    if (qModel.rawQuery.containsIgnoreCase('group by') 
        || qModel.rawQuery.containsIgnoreCase(' limit ')) {
      return false;
    }
    String[] invalidTypes = new String[]{
      'accountcontactrelation',
      'attachment',
      'campaignmember',
      'campaignmemberstatus',
      'contentdocument',
      'contentdocumentlink',
      'contentworkspace',
      'document',
      'dynamic_config__mdt',
      'feeditem',
      'note',
      'recordtype',
      'task'
    };
    return (!invalidTypes.contains(qModel.sObjectType.toLowerCase()));
  }


  public void runQuery(SO_ViewModel model, SO_ViewModel.Query qModel, Boolean withSharing, Boolean isSubCall) {
    if (!String.isEmpty(qModel.sObjectType)) {
      buildRawQuery(model, qModel, withSharing);
    } else {
      extractModelFromRawQuery(qModel);
      String[] fields = processAccessibleFields(qModel, withSharing);
      if (withSharing) {
        removeInaccessibleFields(qModel, fields);
      }        
    }
    replaceGlobals(model, qModel, isSubCall);
    // @todo: Attach related children after chaining queries together
    if (!isSubCall && canUseSetController(qModel)) {
      attachSetController(model, qModel);
    } else {
      attachRecords(model, qModel, isSubCall);
    }

    if (qModel.subQueries != null) {
      for (SO_ViewModel.Query q : qModel.subQueries) {
        runQuery(model, q, withSharing, true);
      }
    }

  }
  
  
  /*****************************************************************************
   * @description Generates a standard set controller, sets pagination 
   * parameters and attaches the records to the view model.
   * @param model an instance of the SO_ViewModel.
  **/
  public void attachSetController(SO_ViewModel model, SO_ViewModel.Query qModel) {
    ApexPages.StandardSetController setController = new ApexPages.StandardSetController(
      Database.getQueryLocator(qModel.rawQuery)
    );
    setController.setPageSize(model.data.properties.pageSize);
    setController.setPageNumber(model.data.properties.pageNumber);
    for (sObject o : setController.getRecords()) {
      SO_ViewModel.sObjectListItem item = new SO_ViewModel.sObjectListItem();
        item.value = o;
      model.data.items.add(item);
    }
    model.data.properties.totalRecords = setController.getResultSize();
    model.data.properties.hasNext = setController.getHasNext();
    model.data.properties.hasPrev = setController.getHasPrevious();
    model.data.success = true;
  }
  
  
  /*****************************************************************************
   * @description queries the database with the generated SOQL query and 
   * attaches the records to the view model. 
   * @param model an instance of the SO_ViewModel.
  **/
  public void attachRecords(SO_ViewModel model, SO_ViewModel.Query qModel, Boolean isSubCall) {
    if (isSubCall && parentValueMapping.keySet().size() == 0) {
      runUnoptimizedQuery(model, qModel);
    } else {
      System.debug(qModel.rawQuery);
      List<sObject> records = Database.query(qModel.rawQuery);
      if (isSubCall) {
        Set<String> pvmKeys = parentValueMapping.keySet();
        Set<String> fields = new Set<String>();
        List<String> fieldList = new List<String>();
        for (String fieldValue : pvmKeys) {
          fields.add(fieldValue.split(';;')[0]);
        }
        fieldList.addAll(fields);
        if (fieldList[0] == '$index') {
          Set<Integer> attachToTop = new Set<Integer>();
          for (String fieldValue : pvmKeys) {
            attachToTop.add(Integer.valueOf(fieldValue.split(';;')[1]));
          }
          for (sObject o : records) {
            addToIndexes(model, o, attachToTop);
          }
        } else {
          // fieldname;;value -> [ 1, 5 ];
          for (sObject o : records) {
            Set<Integer> parentIds = null;
            for (String field : fieldList) {
              String value = String.escapeSingleQuotes(String.valueOf(o.get( field )));
              Set<Integer> compare = parentValueMapping.get( field + ';;' +  value);
              if (parentIds == null) {
                parentIds = compare;
              } else {
                for (Integer id : parentIds) {
                  if (!compare.contains(id)) {
                    parentIds.remove(id);
                  }
                }
              }
            }
            addToIndexes(model, o, parentIds);
          }
        }
      } else {
        for (sObject o : records) {
          SO_ViewModel.sObjectListItem item = new SO_ViewModel.sObjectListItem();
          item.value = o;
          model.data.items.add(item);
        }
      }
      model.data.success = true;
    }
  }

  public void runUnoptimizedQuery(SO_ViewModel model, SO_ViewModel.Query qModel) {
    Pattern standard = Pattern.compile('\\$THIS.([a-zA-Z0-9_-]+)');
    Matcher matcher = standard.matcher(qModel.rawQuery);
    Set<String> fields = new Set<String>();
    String rawQBackup = qModel.rawQuery;
    while (matcher.find()) {
      fields.add(matcher.group(1));
    }
    Integer i = 0;
    for (SO_ViewModel.sObjectListItem item : model.data.items) {
      qModel.rawQuery = rawQBackup;
      for (String field : fields) {
        System.debug('replace: $THIS.' + field);
        System.debug(String.escapeSingleQuotes(String.valueOf(item.value.get( field ))));
        qModel.rawQuery = qModel.rawQuery.replace('$THIS.' + field, String.escapeSingleQuotes(String.valueOf(item.value.get( field ))));          
      }
      parentValueMapping = new Map<String, Set<Integer>>();
      Set<Integer> setSpecial = new Set<Integer>();
      parentValueMapping.put('$index;;'+i,  setSpecial);
      attachRecords(model, qModel, true);
    }
  }

  public void addToIndexes(SO_ViewModel model, sObject o, Set<Integer> indexes) {
    SO_ViewModel.sObjectListItem item = new SO_ViewModel.sObjectListItem();
    item.value = o;
    for (Integer i : indexes) {
      model.data.items[i].children.add(item);
    }
  }
  
  
  /*****************************************************************************
   * @description Processes and combines a parameterized query and sets the
   * rawQuery property of the view model. This will only process one level of
   * query objects, and needs to be called again for each sub-query.
   * @param model an instance of the SO_ViewModel.
   * @param queryObject the current query object to process.
   * @param withSharing flag that removes fields that the current user doesn't
   * have access to.
  **/
  public void buildRawQuery(SO_ViewModel model, SO_ViewModel.Query queryObject, Boolean withSharing) {
    String query = 'SELECT ';    
    queryObject.fields = processAccessibleFields(queryObject, withSharing);    
    query += String.join(queryObject.fields, ', ');
    query += ' FROM ' + queryObject.sObjectType;
    
    if (!String.isEmpty(queryObject.whereClause)) {
      query += ' WHERE ' + queryObject.whereClause;
    }
    
    if (!String.isEmpty(queryObject.groupBy)) {
      query += ' GROUP BY ' + queryObject.groupBy;
    }
    
    if (!String.isEmpty(queryObject.orderBy)) {
      query += ' ORDER BY ' + queryObject.orderBy;
    }
    
    if (queryObject.limitClause != null) {
      query += ' LIMIT ' + String.valueOf(queryObject.limitClause);
    }
    
    queryObject.rawQuery = query;    
  }
  
  
  /*****************************************************************************
   * @description Removes inaccessible fields if withSharing is set to true, 
   * gets metadata for each field, and stores those field describes in the view
   * model
   * @param queryObject The current query object to process.
   * @param withSharing flag that removes fields that the current user doesn't
   * have access to.
   * @return A list of fields the user can access.
  **/
  public String[] processAccessibleFields(SO_ViewModel.Query queryObject, Boolean withSharing) {
    String[] fields = new String[]{};
    for (String field: queryObject.fields) {
      String alias = '';
      Integer index = field.indexOfIgnoreCase(' as ');
      if (index != -1) {
          alias = field.substring(index + 4);
          field = field.substring(0, index);
      }
      if (field.indexOf('(') != -1) {
        fields.add(field);
      } else {
        Schema.DescribeFieldResult fieldDescribe = getFieldResult(queryObject.sObjectType, field);
        if (fieldDescribe != null && (!withSharing || fieldDescribe.isAccessible())) {
          SO_ViewModel.FieldDescribe describe = new SO_ViewModel.FieldDescribe();
          describe.name = fieldDescribe.getName();
          describe.label = fieldDescribe.getLabel();
          describe.type = fieldDescribe.getType().name();
          describe.fieldSize = fieldDescribe.getByteLength() / 3;
          describe.required = !fieldDescribe.isNillable();
          describe.helpText = fieldDescribe.getInlineHelpText();
          describe.isNameField = fieldDescribe.isNameField();          
          if (alias != '') {
              describe.aliasName = alias;
          }
          if (describe.type == 'picklist' || describe.type == 'multipicklist') {
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
              describe.picklistOptions.add(entry.getLabel());
            }
          } else if (describe.type == 'reference') {
            List<Schema.sObjectType> objList = fieldDescribe.getReferenceTo();
            List<String> objs = new String[]{};
            for (Schema.sObjectType obj : objList){
              objs.add(obj.getDescribe().getName());
            }
            describe.relationshipName = String.join(objs, ',');
          }
          queryObject.fieldDescribes.put(field, describe);
          fields.add(field);
        }

      }
    }
    return fields;
  }
  
  /*****************************************************************************
   * @description Given a list of accessible fields, modifies the raw query to
   * query only those fields.
   * @param queryObject The current query object to process.
   * @param withSharing flag that removes fields that the current user doesn't
   * have access to.
  **/
  public void removeInaccessibleFields(SO_ViewModel.Query qModel, String[] fields) {
    Integer indexOf = qModel.rawQuery.indexOfIgnoreCase(' FROM ');
    String newQuery = 'SELECT ' + String.join(fields, ', ') + qModel.rawQuery.substring(indexOf);
    qModel.rawQuery = newQuery;
  }
  
  /*****************************************************************************
   * @description Given an object name and field name (or a path to the field)
   * this will return a 
   * @param sObjectType the sObject's API name
   * @param field the field's API name   
   * @return DescribeFieldResult of the given field or field path
  **/
  public Schema.DescribeFieldResult getFieldResult(String sObjectType, String field) {
    Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
    if (field.indexOf('.') == -1) {
      if (!objectDescribe.fields.getMap().containsKey(field)) {
        return null;
      }
      return objectDescribe.fields.getMap().get(field).getDescribe();
    }
    
    // Field param is a relative path.
    // Recursively parse the field name until we get the target field describe.
    String relationshipName = field.split('\\.')[0];
    for (String subField: objectDescribe.fields.getMap().keySet()) {
      Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(subField).getDescribe();
      if (fieldDescribe.getRelationshipName() == relationshipName) {
        return getFieldResult(
          fieldDescribe.getReferenceTo()[0].getDescribe().getName(),
          field.substringAfter('.')
        );
      }
    }
    return null;
  }
  
  protected Map<String, Set<Integer>> parentValueMapping = new Map<String, Set<Integer>>();
  // @todo: Make standard reference binding work with nesting
  public void optimizeSubQueries(SO_ViewModel model, SO_ViewModel.Query qModel) {
      System.debug(qModel);
      System.debug(qModel.rawQuery);
      Pattern standard = Pattern.compile('(?i)([a-z0-9_-]+) (= \\\'?(\\$PARENT.([a-z0-9_-]+)\\\'?)|in \\([^()$]+\\$PARENT.([a-z0-9_-]+)\\\'?\\))');
      Matcher matcher = standard.matcher(qModel.rawQuery);
      Map<String, String> referenceMap = new Map<String, String>();
      Map<String, String> replacements = new Map<String, String>();
      
      while (matcher.find()) {
        Boolean nested = false;
        String parentField = matcher.group(4);
        String localField = matcher.group(1);
        if (matcher.group(2).indexOf('SELECT') != -1) {
          parentField = matcher.group(5);
          nested = true;
        }
        
        Set<String> values = new Set<String>();
        Integer i=0;
        for (SO_ViewModel.sObjectListItem o : model.data.items) {
          String value = String.escapeSingleQuotes(String.valueOf(o.value.get( parentField )));
          Set<Integer> indexTable;
          if (parentValueMapping.get(localField + ';;' + value) == null) {
            indexTable = new Set<Integer>();
          } else {
            indexTable = parentValueMapping.get(localField + ';;' + value);
          }
          indexTable.add(i++);
          parentValueMapping.put(localField + ';;' + value, indexTable);
          values.add( value );
        }
        List<String> valueList = new List<String>();
        valueList.addAll(values);
        String replacement;
        if (nested) {
          String g2 = matcher.group(2);
          g2 = g2.replace('= \'$PARENT.' + parentField + '\'', ' IN (\'' + String.join( valueList, '\',\'') + '\')' );
          replacement = localField + ' ' + g2;
        } else {
          replacement = localField + ' IN (\'' + String.join( valueList, '\',\'') + '\')';
        }
        replacements.put( matcher.group(0), replacement);
      }

      for (String replacement : replacements.keySet()) {
        System.debug(qModel.rawQuery);
        System.debug(replacement);
        System.debug(replacements.get(replacement));
        qModel.rawQuery = qModel.rawQuery.replace( replacement, replacements.get(replacement) );
      }
  }

  
  /*****************************************************************************
   * @description Replaces global variables from the raw query. This can be
   * extended for making queries more dynamic.
   * @param model an instance of the SO_ViewModel.
  **/
  public void replaceGlobals(SO_ViewModel model, SO_ViewModel.Query qModel, Boolean isSubCall) {
    qModel.rawQuery = qModel.rawQuery.replace('$USERID', UserInfo.getUserId());
    if (qModel.recordId != null) {
      qModel.rawQuery = qModel.rawQuery.replace('$RECORDID', qModel.recordId);
    }

    if (qModel.rawQuery.contains('$$')) {
      replaceQueryFunctions(model, qModel);
    }

    if (isSubCall) {
      optimizeSubQueries(model, qModel);
    }
  }

  public void replaceQueryFunctions(SO_ViewModel model, SO_ViewModel.Query qModel) {
    //Old pattern: Pattern.compile('(?i)\\$\\$([a-z0-9_-]+)\\.([a-z0-9_-]+)\\(\\)\\$\\$');
    Pattern standard = Pattern.compile('(?i)\\$\\$([a-z0-9_-]+)\\.([a-z0-9_-]+)\\((\\\'([^\']+)?\\\')?\\)\\$\\$');
    Matcher matcher = standard.matcher(qModel.rawQuery);
    
    while (matcher.find()) {
      
      String className = matcher.group(1);
      String methodName = matcher.group(2);
      String parameter = '';
      String attributeStr = '()';
      try {
        parameter = matcher.group(4);
        if (matcher.group(3).length() > 0) {
          attributeStr = '(\''+parameter+'\')';
        }
      } catch(Exception e) {}
      System.debug(className);
      System.debug(methodName);
      Callable caller = (Callable) Type.forName(className).newInstance();
      Map<String, Object> attributes = new Map<String, Object>();
      if (qModel.recordId != null) {
        attributes.put('recordId', qModel.recordId);
      }
      attributes.put('userId', UserInfo.getUserId());
      attributes.put('param', parameter);
      String replacement = (String) caller.call(methodName, attributes);
      if (replacement == null) replacement = '';
      System.debug(replacement);
      System.debug('$$' + className + '.' + methodName + '()$$');
      
      qModel.rawQuery = qModel.rawQuery.replace('$$' + className + '.' + methodName + attributeStr + '$$', replacement);
    }
  }
}