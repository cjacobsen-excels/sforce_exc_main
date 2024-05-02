/**
 * @author Ed Montalbano
 * @date 11-20-2019
 *
 * @group API
 *
 * @description This is the base API used for rapidly developing custom lightning
 * components. Components will use SO_ViewModel to send data into and get data
 * out of Salesforce. 
**/
public class SO_API {    
    /*****************************************************************************
     * @description Loads the Dynamic_Config__mdt schema specified.
     * @param viewModel the JSON string of the component's SO_ViewModel
     * @return JSON string of the Schema
     * @example
     * SO_API.loadSchema('mySchema');
    **/
    @AuraEnabled(cacheable=true)
    public static String loadSchema(String schemaName) {
      Dynamic_Config__mdt schema = [SELECT json__c FROM Dynamic_Config__mdt WHERE DeveloperName = :schemaName];
      return schema.json__c;
    }
      
    /*****************************************************************************
     * @description Queries Salesforce and returns the new SO_ViewModel as a 
     * string
     * @param viewModel the JSON string of the component's SO_ViewModel
     * @return JSON string of SO_ViewModel
     * @example
     * SO_API.getAll('{"query": {"rawQuery": "SELECT ..."}}');
    **/
    @AuraEnabled
    public static String getAll(String viewModel) {
      SO_DAL dal = new SO_DAL();
      return serializeViewModel(dal.getAll(deserializeViewModel(viewModel), true));
    }
    
    
    /*****************************************************************************
     * @description Upserts records passed in the ViewModel's data.items attribute.
     * @param viewModel the JSON string of the component's SO_ViewModel
     * @param upsertAll the JSON string of the component's SO_ViewModel
     * @return JSON string of SO_ViewModel
     * @example
     * SO_API.upsertAll('{"data": {"items": {"Id": "..."}}}', false);
    **/
    @AuraEnabled
    public static String upsertAll(String viewModel, Boolean modifiedOnly) {
      if (modifiedOnly == null) {
        modifiedOnly = true;
      }
      SO_DAL dal = new SO_DAL();
      SO_ViewModel model = dal.upsertAll(deserializeViewModel(viewModel), modifiedOnly);
      model.data.items = null;
      return serializeViewModel(dal.getAll(model, true));
    }
    
    
    /*****************************************************************************
     * @description Deletes records passed in the ViewModel's data.items attribute.
     * @param viewModel the JSON string of the component's SO_ViewModel
     * @return JSON string of SO_ViewModel
     * @example
     * SO_API.delete('{"data": {"items": {"Id": "..."}}}', true);
    **/
    @AuraEnabled
    public static String deleteAll(String viewModel, Boolean markedOnly) {
      SO_DAL dal = new SO_DAL();
      return serializeViewModel(dal.deleteAll(deserializeViewModel(viewModel), markedOnly));
    }
  
  
    /*****************************************************************************
     * @description Searches all fields of an object type with SOSL
     * @param sObjectType the sObject type to search.
     * @param query the string to search against the database.
     * @param returnFields the fields to return after the search
     * @return JSON string of the search results
     * @example
     * SO_API.searchAll('Contacts', 'John D', 'FirstName,LastName,Email')
     * -> [ {Snippet: '<mark>John D</mark>oe', FirstName: 'John', LastName: 'Doe', Email: 'j.doe@gmail.com'}, ...];
    **/
    @AuraEnabled
    public static string searchAll(String sObjectType, String query, String returnFields){
      SO_DAL dal = new SO_DAL();
      List<Map<String, Object>> results = dal.searchAll(sObjectType, query, returnFields);
      if (results == null) {
        return '[]';
      }
      return JSON.serialize(results);
    }
    
    
    /*****************************************************************************
     * @description Converts a JSON string representation of the view model into
     * an SO_ViewModel object. This method can be overridden if an API extension
     * uses an extended version of the SO_ViewModel class.
     * @param viewModel the JSON string of the component's SO_ViewModel.
     * @return SO_ViewModel object instance.
     * @example
     * SO_API.deserializeViewModel('{"query"...}', '{"field__c": "value", ...}');
    **/
    public static SO_ViewModel deserializeViewModel(String viewModel) {
      return (SO_ViewModel)JSON.deserialize(viewModel, SO_ViewModel.class);
    }
    
    
    /*****************************************************************************
     * @description Converts an SO_ViewModel object into a JSON string 
     * representation. This method is currently just a wrapper for JSON.serialize.
     * It may be extended to first remove sensitive data from the ViewModel before
     * sending it to the client.
     * @param model an instance of the SO_ViewModel to send to a component.
     * @return JSON string for the component's view model.
     * @example
     * SO_API.serializeViewModel(model);
    **/
    public static String serializeViewModel(SO_ViewModel model) {
      return JSON.serialize(model);
    }
    
  }