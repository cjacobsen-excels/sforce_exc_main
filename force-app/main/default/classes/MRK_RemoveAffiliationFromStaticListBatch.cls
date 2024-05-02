global class MRK_RemoveAffiliationFromStaticListBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Mrk_Sync_Id__c,Marketo_Static_List_IdF__c, hed__EndDate__c, Marketo_Contact_Id__c,Mrk_Removed_From_Static_List__c FROM hed__Affiliation__c WHERE Mrk_Sync_Id__c != null AND hed__EndDate__c != null AND hed__EndDate__c < TODAY AND Mrk_Removed_From_Static_List__c = false';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<hed__Affiliation__c> records) {
        List<hed__Affiliation__c> updateAff = new List<hed__Affiliation__c>();
        System.debug(records.size());
        for(hed__Affiliation__c aff : records){
            System.debug(aff);
            hed__Affiliation__c affUp = new hed__Affiliation__c();
            affUp.Id = aff.Id;
            affUp.Mrk_Removed_From_Static_List__c = true;
            updateAff.add(affUp);
        }
        ID jobID = System.enqueueJob(new MRK_TriggerCalloutHelper(new List<sObject>(), records, 'hed__Affiliation__c', 'Delete', new List<hed__Affiliation__c>()));

        if(!updateAff.isEmpty()){
            Database.update(updateAff,false);
        }
    }
    
    global void finish(Database.BatchableContext bc) {

    }
}