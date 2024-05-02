/**
 * Created by mnahar on 22/06/21.
 * Trigger to automatically create the contact history records when duplicate contacts are merged.
 */

global with sharing class ContactMergeTDTM extends hed.TDTM_Runnable{

    global override hed.TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList, hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        hed.TDTM_Runnable.DmlWrapper dmlWrapper = new hed.TDTM_Runnable.DmlWrapper();

        if (triggerAction == hed.TDTM_Runnable.Action.AfterDelete) {
            List<Contact_Merge_History__c> historyList = new List<Contact_Merge_History__c>();
            for(Contact contactRecord : (List<Contact>)oldList){
                if(contactRecord.MasterRecordId != null){
                    Contact_Merge_History__c conHistoryRecord = new Contact_Merge_History__c();
                    conHistoryRecord.Email__c = contactRecord.Email;
                    conHistoryRecord.First_Name__c = contactRecord.FirstName;
                    conHistoryRecord.Last_Name__c = contactRecord.LastName;
                    conHistoryRecord.Parent_Contact__c = contactRecord.MasterRecordId;
                    conHistoryRecord.SF_Contact_Id__c = contactRecord.Id;
                    conHistoryRecord.SIS_Id__c = contactRecord.Student_ID_Number_SIS_ID__c ;
                    historyList.add(conHistoryRecord);
                }
            }
            dmlWrapper.objectsToInsert.addAll((List<SObject>) historyList);
        }
        return dmlWrapper;
    }
}