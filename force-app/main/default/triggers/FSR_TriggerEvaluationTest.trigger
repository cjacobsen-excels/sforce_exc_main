/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
trigger FSR_TriggerEvaluationTest on Evaluation__c(after insert, after update){
    if(Trigger.isAfter){
		Set<Id> UpdateSharing = new Set<Id>();
		if(Trigger.isInsert){
			FormulaShareDispatcher.shareRecords('Evaluation__c', trigger.newMap.keySet());
		}
		if(Trigger.isUpdate){
			Set<Id> EvaluationIdChanged = new Set<Id>();
			for(Evaluation__c c : Trigger.new){
				if(c.Faculty_Member__c != Trigger.oldMap.get(c.Id).Faculty_Member__c){
					EvaluationIdChanged.add(c.Id);
				}
			}

			if(!EvaluationIdChanged.isEmpty()){
				FormulaShareDispatcher.shareRecords('Evaluation__c', EvaluationIdChanged);
			}

		}
	}
}