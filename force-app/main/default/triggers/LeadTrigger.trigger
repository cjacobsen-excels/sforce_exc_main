trigger LeadTrigger on Lead (after insert,after update) {
    if(trigger.isUpdate){
        LeadServices.MoveCasesOnLeadConversion(trigger.new,trigger.old);
    }

    LeadServices.UpdateMarketingFields(trigger.newMap,trigger.oldMap);
}