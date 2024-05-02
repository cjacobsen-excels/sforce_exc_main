/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
trigger FSR_TriggerContactTest on Contact(after insert, after update){
	if(Trigger.isAfter){
		if(Trigger.isInsert){
			FormulaShareDispatcher.shareRecords('Contact', trigger.newMap.keySet());
		}

		if(Trigger.isUpdate){
			Set<Id> facIdChanged = new Set<Id>();
			for(Contact c : Trigger.new){
				if(c.Faculty_ID__c != Trigger.oldMap.get(c.Id).Faculty_ID__c){
					facIdChanged.add(c.Id);
				}
			}

			if(!facIdChanged.isEmpty()){
				Set<Id> UpdateSharingAffiliation = new Set<Id>();
				UpdateSharingAffiliation = FormulaShareDispatcher.getChangedChildRecords(facIdChanged, 'hed__Affiliation__c', 'hed__Contact__c');

				Set<Id> UpdateSharingAttribute = new Set<Id>();
				UpdateSharingAttribute = FormulaShareDispatcher.getChangedChildRecords(facIdChanged, 'hed__Attribute__c', 'hed__Contact__c');

				//Set<Id> UpdateSharingCourse_Offering = new Set<Id>();
				//UpdateSharingCourse_Offering = FormulaShareDispatcher.getChangedChildRecords(facIdChanged, 'hed__Course_Offering__c', 'hed__Contact__c');

				Set<Id> UpdateSharingEvaluation = new Set<Id>();
				UpdateSharingEvaluation = FormulaShareDispatcher.getChangedChildRecords(facIdChanged, 'Evaluation__c', 'Faculty_Member__c');

				Set<Id> UpdateSharingPayment = new Set<Id>();
				UpdateSharingPayment = FormulaShareDispatcher.getChangedChildRecords(facIdChanged, 'Payment__c', 'Pay_To__c');

				FormulaShareDispatcher.shareRecords('Contact', facIdChanged);

				if(!UpdateSharingAffiliation.isEmpty()){
					FormulaShareDispatcher.shareRecords('hed__Affiliation__c', UpdateSharingAffiliation);
				}
				if(!UpdateSharingAttribute.isEmpty()){
					FormulaShareDispatcher.shareRecords('hed__Attribute__c', UpdateSharingAttribute);
				}
				//if(!UpdateSharingCourse_Offering.isEmpty()){
				//	FormulaShareDispatcher.shareRecords('hed__Course_Offering__c', UpdateSharingCourse_Offering);
				//}
				if(!UpdateSharingEvaluation.isEmpty()){
					FormulaShareDispatcher.shareRecords('Evaluation__c', UpdateSharingEvaluation);
				}
				if(!UpdateSharingPayment.isEmpty()){
					FormulaShareDispatcher.shareRecords('Payment__c', UpdateSharingPayment);
				}
			}
		}
	}
}