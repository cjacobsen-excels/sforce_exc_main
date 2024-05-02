trigger MRK_MarketoLogTrigger on Marketo_Log__c (after insert) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            MRK_LoggerHelper.notify(Trigger.new);
        }
    }
}