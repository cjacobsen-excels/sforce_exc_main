/**
 * Created by mnahar on 24/06/21.
 */

public without sharing class PreApplicationSelectionsController {

   // @AuraEnabled
  //  public static List<String> getApplicationTerms() {
     //   List<String> optionslist = new List<String>();
      //  try {
        //    SObjectField picklistUsingGlobal = SObjectType.Account.fields.Term__c.getSObjectField();
           // List<PicklistEntry> entries = picklistUsingGlobal.getDescribe().getPicklistValues();
           // optionslist.add('--None--');
           // for (Schema.PicklistEntry pv : entries) {
           //     optionslist.add(pv.getValue());
          //  }
       //     return optionslist;
      //  } catch (Exception ex) {
     //       throw new AuraHandledException(ex.getMessage());
    //    }
   // }
 @AuraEnabled   
 public static List<String> getApplicationTerms() {
        List<String> optionslist = new List<String>();
      try {
            optionslist.add('--None--');
            for (hed__Term__c objTerm : [
                    SELECT Id, Name
                    FROM hed__Term__c
                    WHERE Open_for_Applications__c = TRUE]) {
                optionslist.add(objTerm.Name);
            }
            return optionslist;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<String> getAreaOfInterest() {
        List<String> optionslist = new List<String>();
        try {
            SObjectField picklistUsingGlobal = SObjectType.Account.fields.Area__c.getSObjectField();
            List<PicklistEntry> entries = picklistUsingGlobal.getDescribe().getPicklistValues();
            optionslist.add('--None--');
            for (Schema.PicklistEntry pv : entries) {
                optionslist.add(pv.getValue());
            }
            return optionslist;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    public static List<String> getLevelOfInterest() {
        List<String> optionslist = new List<String>();
        try {
            SObjectField picklistUsingGlobal = SObjectType.Account.fields.Level__c.getSObjectField();
            List<PicklistEntry> entries = picklistUsingGlobal.getDescribe().getPicklistValues();
            optionslist.add('--None--');
            for (Schema.PicklistEntry pv : entries) {
                optionslist.add(pv.getValue());
            }
            return optionslist;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getAcademicPrograms(String term, String level, String area) {
        Map<String, String> optionslist = new Map<String, String>();
        try {
            optionslist.put('--None--', '');
            for (Account objAccount : [
                    SELECT Id, Formatted_Name__c
                    FROM Account
                    WHERE Starting_Term__r.Name = :term
                    AND Level__c = :level
                    AND Area__c = :area
                    AND traa_Open_to_Application_Submissions__c = 'Yes'
            ]) {
                optionslist.put(objAccount.Formatted_Name__c, objAccount.Id);
            }
            return optionslist;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

}