public with sharing class MRK_InterfaceController {
    
    @AuraEnabled
    public static Marketo_Api_Settings__c getSettings(){
        Marketo_Api_Settings__c csMrk = Marketo_Api_Settings__c.getOrgDefaults();
        return csMrk;
    }

    @AuraEnabled
    public static Marketo_Api_Setting__mdt getMDTSetting(){
        Marketo_Api_Setting__mdt mainMarketoSetting = [SELECT Number_Of_Retries__c, Id, When_to_Clear_Logs__c, Who_Should_be_notified__c, Notifications_On__c, Marketo_Notification_Template__c 
                                    FROM Marketo_Api_Setting__mdt Limit 1];
        return mainMarketoSetting;
    }

    @AuraEnabled
    public static Marketo_Api_Settings__c setSettings(String mrkCsStr){
        Marketo_Api_Settings__c mrkcs = (Marketo_Api_Settings__c) System.JSON.deserialize(mrkCsStr, Marketo_Api_Settings__c.class);

        Database.update(mrkcs,false);
        return mrkcs;
    }
}