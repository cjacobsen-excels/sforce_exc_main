/**
 * @author Ed Montalbano
 * @date 11-20-2019
 *
 * @group API
 *
 * @description This is the view model used to prop up custom lightning 
 * components. This data is shared between the component and the API to generate
 * queries, fetch data, and build the view. This can be extended to support more
 * specific data structures and algorithms used to build a component.
 * 
 * @example: {
    query: {
      rawQuery: 'SELECT Id, Name FROM Account WHERE Id = $RECORDID ORDER BY CreatedDate DESC LIMIT 10',
      whereClause: 'Id = $RECORDID',
      groupBy: '',
      orderBy: 'CreatedDate DESC',
      nullsFirst: false,
      limitClause: 10,
      recordId: '0031500001aeGlaAAE',
      subQueries: [ { rawQuery: 'SELECT ...' } ]
    },
    data: {
      items : [
        {
          value: {Id: '0031500001aeGlaAAE', Name: 'Alice Black'},
          modified: false,
          children: [ ... ]
        }
      ],
      success: true,
      info: {
        
      },
      properties: {
        
      }
    }
 * }
}
**/
global class SO_ViewModel {
  /**************************************************************************
   * @description Contains data from the component describing how to query the
   * data. 
  **/
  public Query query { get; set; }
  

  /**************************************************************************
   * @description Contains a list of data from the component describing how to query the
   * data. 
  **/
  public Query[] queries { get; set; }

  /**************************************************************************
   * @description On query, contains the data returned from salesforce, success 
   * or error messages, and properties that describe the results. On upsert / 
   * delete, contains records to insert, update or delete. 
  **/
  public Data data { get { if (data == null) { data = new Data(); } return data; } set; }

  public class Query {  
    /**************************************************************************
     * @description Optional raw SOQL query string. If this is provided, none of
     * the other properties will be used.
    **/
    public String rawQuery { get; set; }

    /**************************************************************************
     * @description A list of fields to include in the query
    **/
    public String[] fields { get { if (fields == null) { fields = new String[]{}; } return fields; } set; }

    public String sObjectType { get; set; }

    /**************************************************************************
     * @description (Optional) The where clause of the query. Ex: 
     * "Field__c = 'value' AND OtherField__c 
    **/
    public String whereClause { get; set; }

    /**************************************************************************
     * @description (Optional) Group by clause of the query. Ex: "Lead Source"
    **/
    public String groupBy { get { if (groupBy == null) { groupBy = ''; } return groupBy; } set; }

    /**************************************************************************
     * @description (Optional) Order by clause of the query. Default:
     * "CreatedDate DESC"
    **/
      public String orderBy { get { if (orderBy == null) { orderBy = 'CreatedDate DESC'; } return orderBy; } set; }

    /**************************************************************************
     * @description (Optional) when true, this flag sorts null values to the top 
     * of an ascending sort. Default: false
    **/
    public Boolean nullsFirst { get { if (nullsFirst == null) { nullsFirst = false; } return nullsFirst; } set; }

    /**************************************************************************
     * @description The limit clause of the query. Default: 10,000 (Salesforce
     * governor limit)
    **/
    public Integer limitClause { get { if (limitClause == null) { limitClause = 10000; } return limitClause; } set; }
    
    /**************************************************************************
     * @description The record ID to filter the query by.
    **/
    public String recordId { get; set; }
    
    public Map<String, FieldDescribe> fieldDescribes { get { if (fieldDescribes == null) { fieldDescribes = new Map<String, FieldDescribe>(); } return fieldDescribes; } set; }
    
    public Query[] subQueries { get; set; }
  }
  
  public class Data {
    /**************************************************************************
     * @description The list of items returned from the query / queries.
    **/
    public sObjectListItem[] items { get { if (items == null) { items = new sObjectListItem[]{}; } return items; } set; }
    
    /**************************************************************************
     * @description Flag set by the data access layer indicating an action was
     * successful or failed.
    **/    
    public Boolean success { get; set; }
    
    
    /**************************************************************************
     * @description A collection information containting informative messages,
     * exception messages, save results, delete results, and related info. 
    **/
    public Info info { get { if (info == null) { info = new Info(); } return info; } set; }
    
    /**************************************************************************
     * @description A collection of properties used to build a list of records.
     * Information like the total number of records, pagination data, and a JSON
     * payload that can contain custom properties.
    **/
    public ResultProperties properties { get { if (properties == null) { properties = new ResultProperties(); } return properties; } set; }
    
    
    
  }
  public class Info {
    /*************************************************************************
     * @description An informative message. This will be displayed in a gray
     * ribbon on the component. Prepend "Toast:" to the message to make the
     * message popup in a toast instead of a ribbon.
    **/
    public String infoMessage { get; set; }
    
    /*************************************************************************
     * @description A human-friendly exception message if an exception was
     * thrown. This will be displayed in a red error ribbon on the component.
     * Prepend "Toast:" to the message to make the message popup in a toast 
     * instead of a ribbon.
    **/
    public String errorMessage { get; set; }
    
    /*************************************************************************
     * @description A human-friendly indication that the action was successful.
     * Prepend "Toast:" to the message to make the message popup in a toast 
     * instead of a ribbon.
    **/
    public String successMessage { get; set; }
    
    /*************************************************************************
     * @description Debugging information for use during development.
    **/
    public String debug { get; set; }
    
    /*************************************************************************
     * @description A list of save results of an attempted upsert.
    **/
    public Database.SaveResult[] saveResults { get { if (saveResults == null) { saveResults = new Database.SaveResult[]{}; } return saveResults; } set; }
    
    /*************************************************************************
     * @description A count of the number of results successfully saved.
    **/
    public Integer saveResultSuccesses { get { if (saveResultSuccesses == null) { saveResultSuccesses = 0;} return saveResultSuccesses; } set; }
    
    /*************************************************************************
     * @description A count of the number save result errors.
    **/
    public Integer saveResultErrors { get { if (saveResultErrors == 0) { saveResultErrors = 0;} return saveResultErrors; } set; }

    /*************************************************************************
     * @description A list of messages explaining why attempted saves failed
    **/
    public String[] saveResultErrorMessages { get { if (saveResultErrorMessages == null) { saveResultErrorMessages = new String[]{}; } return saveResultErrorMessages; } set; }

    /*************************************************************************
     * @description A list of delete results. 
    **/
    public Database.DeleteResult[] deleteResults { get { if (deleteResults == null) { deleteResults = new Database.DeleteResult[]{}; } return deleteResults; } set; }

    /*************************************************************************
     * @description A count of the number of records successfully deleted.
    **/
    public Integer deleteResultSuccesses { get { if (deleteResultSuccesses == null) { deleteResultSuccesses = 0; } return deleteResultSuccesses; } set; }

    /*************************************************************************
     * @description A count of the number of records that failed to delete.
    **/
    public Integer deleteResultErrors { get { if (deleteResultErrors == null) { deleteResultErrors = 0; } return deleteResultErrors; } set; }

    /*************************************************************************
     * @description A list of error messages explaining why attempted deletes
     * failed
    **/
    public String[] deleteResultErrorMessages { get { if (deleteResultErrorMessages == null) { deleteResultErrorMessages = new String[]{}; } return deleteResultErrorMessages; } set; }
  }
  
  public class ResultProperties {
    /**************************************************************************
     * @description A count of the total number of records. May not always be
     * set.
    **/
    public Integer totalRecords { get; set; }

    /**************************************************************************
     * @description Indication of if there is a page after the current page
    **/
    public Boolean hasNext { get; set; }
    
    /**************************************************************************
     * @description Indication of if there is a page before the current page
    **/
    public Boolean hasPrev { get; set; }
    
    /**************************************************************************
     * @description The current page. Starts at 1 instead of 0. 
    **/
    public Integer pageNumber { get { if (pageNumber == null) { pageNumber = 1; } return pageNumber; } set; }
    
    /**************************************************************************
     * @description The number of records displayed on each page.
    **/
    public Integer pageSize { get { if (pageSize == null) { pageSize = 50; } return pageSize; } set; }    
    
    /**************************************************************************
     * @description A JSON string which contains custom result properties. If
     * set, it will be converted to an object by the lightning component.
    **/
    public String json { get { if (json == null) { json = ''; } return json; } set; }
  }
  
  
  public class FieldDescribe {
    public String name { get; set; }
    public String label { get; set; }
    public String type { get; set; }
    public Integer fieldSize { get; set; }
    public Boolean required { get { if (required == null) { required = false; } return required; } set; }
    public String helpText { get; set; }
    public Boolean isNameField { get { if (isNameField == null) { isNameField = false; } return isNameField; } set; }
    public String[] picklistOptions { get { if (picklistOptions == null) { picklistOptions = new String[]{}; } return picklistOptions; } set; }
    public String relationshipName { get; set; }    
    public String aliasName { get; set; }
  }

  /**
   * @group API
   * @description This represents a single record. If we are chaining queries
   * together, we can attach children records to this object.
  **/
  public class sObjectListItem {
    public sObject value { get; set; }
    public String properties { get; set; }
    public sObjectListItem[] children { get { if (children == null) { children = new sObjectListItem[]{}; } return children; } set; }
    public Boolean modified { get { if (modified == null) { modified = false; } return modified; } set; }
    public Boolean toDelete { get { if (toDelete == null) { toDelete = false; } return toDelete; } set; }
  }
}