global class UpdateExternalSectionIDBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all Course Offering records where the hed__Section_ID__c is not null
        //return Database.getQueryLocator('SELECT Id, hed__Section_ID__c FROM hed__Course_Offering__c WHERE hed__Section_ID__c != NULL');
        return Database.getQueryLocator('SELECT Id, Name, (SELECT Id, Faculty_Status__c FROM Qualified_Faculty__r WHERE Faculty_Status__c = \'Active\') FROM hed__Course_Offering__c WHERE Qualified_Faculty__c != null');
        
    }
    
    global void execute(Database.BatchableContext bc, List<hed__Course_Offering__c> records) {
        // Update the External_Section_ID__c field for each record
        for(hed__Course_Offering__c record : records) {
            record.External_Section_ID__c = record.hed__Section_ID__c;
        }
        update records;
    }
    
    global void finish(Database.BatchableContext bc) {
        // This method can be used to send an email notification, execute post-processing operations, etc.
    }
}