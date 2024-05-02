/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
trigger FSR_TriggerhedAttributeTest on hed__Attribute__c(after insert, after update){
    if(Trigger.isAfter){
		Set<Id> UpdateSharing = new Set<Id>();
		if(Trigger.isInsert){
			FormulaShareDispatcher.shareRecords('hed__Attribute__c', trigger.newMap.keySet());
		}
		if(Trigger.isUpdate){
			Set<Id> AttributeIdChanged = new Set<Id>();
			for(hed__Attribute__c c : Trigger.new){
				if(c.hed__Contact__c != Trigger.oldMap.get(c.Id).hed__Contact__c){
					AttributeIdChanged.add(c.Id);
				}
			}

			if(!AttributeIdChanged.isEmpty()){
				FormulaShareDispatcher.shareRecords('hed__Attribute__c', AttributeIdChanged);
			}

		}
	}
}