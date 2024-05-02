public with sharing class MRK_ClearLogsBatch implements Database.Batchable<sObject>, Database.Stateful{

    public Marketo_Api_Setting__mdt mainMarketoSetting;
    public Datetime nowTime = System.now();

    public MRK_ClearLogsBatch(){
        this.mainMarketoSetting = [SELECT Number_Of_Retries__c, Id, When_to_Clear_Logs__c, Who_Should_be_notified__c, Notifications_On__c, Marketo_Notification_Template__c 
                                    FROM Marketo_Api_Setting__mdt Limit 1];
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        Integer i = Integer.valueOf(mainMarketoSetting.When_to_Clear_Logs__c);
        DateTime comp = mainMarketoSetting.When_to_Clear_Logs__c != null ? nowTime.addDays(-i) : nowTime.addDays(-1);
        System.debug(comp);
        String query = 'SELECT Id, CreatedDate FROM Marketo_Log__c WHERE CreatedDate <: comp';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Marketo_Log__c> scope){
        System.debug(scope);
        if(mainMarketoSetting.When_to_Clear_Logs__c != null){
            Database.delete(scope,false);
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}