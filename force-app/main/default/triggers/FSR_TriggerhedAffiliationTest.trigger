/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
trigger FSR_TriggerhedAffiliationTest on hed__Affiliation__c(after insert, after update){
    if(Trigger.isAfter){
		if(Trigger.isInsert){
			FormulaShareDispatcher.shareRecords('hed__Affiliation__c', trigger.newMap.keySet());
		}
		if(Trigger.isUpdate){
			Set<Id> UpdateSharing = new Set<Id>();
			for(hed__Affiliation__c c : Trigger.new){
				if(c.hed__Contact__c != Trigger.oldMap.get(c.Id).hed__Contact__c){
					UpdateSharing.add(c.Id);
				}
			}

			if(!UpdateSharing.isEmpty()){
				FormulaShareDispatcher.shareRecords('hed__Affiliation__c', UpdateSharing);
			}

		}
	}
}