trigger AccountTrigger on Account (after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            List<Account> acc = new List<Account>();
            for(Account a : Trigger.new){
                if(a.Marketo_Static_List_Id__c == null && a.POP_Code__c != '' && a.RecordTypeId == devRecordTypeId){
                    acc.add(a);
                }
            }

            if(!acc.isEmpty()){
                ID jobID = System.enqueueJob(new MRK_NewPartnerAccountHelper(acc));
            }
        }

        if(Trigger.isUpdate){
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            List<Account> acc = new List<Account>();
            for(Account a : Trigger.new){
                if(a.Marketo_Static_List_Id__c == null && a.POP_Code__c != '' && a.POP_Code__c != Trigger.oldMap.get(a.Id).POP_Code__c  && a.RecordTypeId == devRecordTypeId){
                    acc.add(a);
                }
            }

            if(!acc.isEmpty()){
                ID jobID = System.enqueueJob(new MRK_NewPartnerAccountHelper(acc));
            }
        }
    }
}