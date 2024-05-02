/**
 * @author Ed Montalbano
 * @date 11-22-2019
 *
 * @group API
 *
 * @description This is a collection of tools meant to make writing test code
 * faster and easier. Keep hard-coded test data out of this class, as this class
 * is meant to easily travel between projects without needing modification.
**/
@isTest
public class SO_TestUtil {
  
  /*****************************************************************************
   * @description Method overloading to make the fieldList parameter optional.
   * @param sObjectType The type of sObject to generate.
   * @return A new sObject with required fields containing random data.
   * @example
   * SO_TestUtil.populateNewObject('Account');
  **/
  public static sObject populateNewObject(String sObjectType) {
    String[] ignoreFields = new String[]{'IsCustomerPortal'}; // ignore this read only field 
    return populateNewObject(sObjectType, new String[]{}, ignoreFields);
  }
  
  
  /*****************************************************************************
   * @description Creates an sObject of the specified type and attempts to 
   * prefill all required or specified fields
   * @param sObjectType The type of sObject to generate.
   * @param fieldList A list of fields to also add random data into.
   * @return A new sObject with fields containing random data.
   * @example
   * SO_TestUtil.populateNewObject('Account', new String[]{'Name', 'Custom_Field__c'});
  **/
  public static sObject populateNewObject(String sObjectType, String[] fieldList, String[] ignoreList) {
    Set<String> fields = lowercase(fieldList);
    Set<String> ignoreFields = lowercase(ignoreList);
    Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
    sObject sObj = Schema.getGlobalDescribe().get(sObjectType).newSObject() ;
    
    for (String field: objectDescribe.fields.getMap().keySet()) {
      Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(field).getDescribe();
      if (!ignoreFields.contains(field.toLowerCase()) && fieldDescribe.isUpdateable() && (!fieldDescribe.isNillable() || fields.contains(field.toLowerCase()))) {
        String fieldType = fieldDescribe.getType().name().toLowerCase();
        if (fieldType.contains('picklist')) {
          List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
          Integer max = entries.size();
          Integer index = Integer.valueOf(Math.floor(Math.random() * max));
          sObj.put(field, entries[index].getLabel());
        } else if (fieldType == 'textarea' || fieldType == 'string' || fieldType == 'anytype'){
            // @todo: Use the fieldDescribe ByteLength to set the max size of the sentence.
            sObj.put(field, words(1, 6, 2, 5));
          } else if (fieldType == 'address'){
            
          } else if (fieldType == 'date'){
            
          } else if (fieldType == 'time'){
            
          } else if (fieldType == 'datetime'){
            
          } else if (fieldType == 'integer'){
            Integer random = (Math.round(Math.random() * 200));
            sObj.put(field, random);
          } else if (fieldType == 'percent'){
            Double random = (Math.round(Math.random() * 100)) / 100;
            sObj.put(field, random);
          } else if (fieldType == 'phone'){
            String phone = '+1 (' + number(3) + ') ' + number(3) + '-' + number(4);
            sObj.put(field, phone);
          } else if (fieldType == 'reference'){
            // It would be nice if we could set a flag to automatically create these references too
          } else if (fieldType == 'email'){
            String email = String.join(words(4,21, 2, 2).split(' '), '@') + 'com';
            sObj.put(field, email);
          } else if (fieldType == 'currency'){
            Double random = (Math.round(Math.random() * 123235)) / 100;
            sObj.put(field, random);
          } else if (fieldType == 'url'){
            
          } else if (fieldType == 'boolean'){
            if (field.toLowerCase() != 'IsCustomerPortal') {
              Boolean random = (Math.round(Math.random()) == 0);
              sObj.put(field, random);
            }
          }
      }
    }
    
    return sObj;
  }
  
  
  /*****************************************************************************
   * @description Converts a list of field names to a lowercase set. Simplifies
   * searching to see if an iterated over field is one specified by the
   * developer.
   * @param fieldList A list of field names.
   * @return A set of field names, with all names converted to lowercase.
   * @example
   * lowercase(new String[]{'Name', 'Custom_Field__c'});
   * returns -> Set<String>{'name', 'custom_field__c'};
  **/
  public static Set<String> lowercase(List<String> fieldList) {
    Set<String> fields = new Set<String>();
    for (String field : fieldList) {
      fields.add(field.toLowerCase());
    }
    return fields;
  }
  
  
  /*****************************************************************************
   * @description Generates a random string of letters of size `len`
   * @param len The number of characters in the word
   * @return A string of letters
   * @example
   * word(5) -> 'gbhjg';
  **/
  public static String word(Integer len) {
    final String chars = 'abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
       Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
       randStr += chars.substring(idx, idx+1);
    }
    return randStr; 
  }
  
  
  /*****************************************************************************
   * @description Generates a random string of numbers of size `len`
   * @param len The number of digits in the number
   * @return A string of numbers
   * @example
   * number(3) -> '452';
  **/
  public static String number(Integer len) {
    final String chars = '1234567890';
    String randStr = '';
    while (randStr.length() < len) {
       Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
       randStr += chars.substring(idx, idx+1);
    }
    return randStr;
  }
  
  
  /*****************************************************************************
   * @description Generates a random string of words which vary in size and have
   * spaces between them. 
   * @param minLen The minimum number of letters in a word
   * @param maxLen The maximum number of letters in a word
   * @param minWords The minimum number of words
   * @param maxWords The maximum number of words
   * @return A string of letters resembling a sentence.
   * @example
   * words(1,3,5,6) -> 'fdj g ia j asf';
  **/
  public static String words(Integer minLen, Integer maxLen, Integer minWords, Integer maxWords) {
    Integer words = (Math.round( Math.random() * (maxWords - minWords)) + minWords);
    String[] collection = new String[]{};
    for (Integer i=0; i<words; i++) {
      Integer letters = (Math.round( Math.random() * (minLen - maxLen)) + minLen);
      collection.add(word(letters));
    }
    System.debug(collection[0]);
    //collection[0] = collection[0].substring(0,1).toUpperCase() + collection[0].substring(1);
    return String.join(collection, ' ') + '.';
  }
}