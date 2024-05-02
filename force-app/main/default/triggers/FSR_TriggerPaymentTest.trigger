/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
trigger FSR_TriggerPaymentTest on Payment__c(after insert, after update){
    if(Trigger.isAfter){
		Set<Id> UpdateSharing = new Set<Id>();
		if(Trigger.isInsert){
			FormulaShareDispatcher.shareRecords('Payment__c', trigger.newMap.keySet());
		}
		if(Trigger.isUpdate){
			Set<Id> payIdChanged = new Set<Id>();
			for(Payment__c c : Trigger.new){
				if(c.Pay_To__c != Trigger.oldMap.get(c.Id).Pay_To__c){
					payIdChanged.add(c.Id);
				}
			}

			if(!payIdChanged.isEmpty()){
				FormulaShareDispatcher.shareRecords('Payment__c', payIdChanged);
			}

		}
	}
}