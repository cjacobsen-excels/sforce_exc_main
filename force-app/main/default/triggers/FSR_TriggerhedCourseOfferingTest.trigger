/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
trigger FSR_TriggerhedCourseOfferingTest on hed__Course_Offering__c(after insert, after update){
	if(Trigger.isAfter){
		Set<Id> UpdateSharing = new Set<Id>();
		if(Trigger.isInsert){
			FormulaShareDispatcher.setSharingCourseOffering(trigger.newMap.keySet());
			//FormulaShareDispatcher.shareRecords('hed__Course_Offering__c', trigger.newMap.keySet());
		}

		if(Trigger.isUpdate){
			Set<Id> updatesToCourseEnrollment = new Set<Id>();
			Set<Id> insertedOrUpdated = new Set<Id>();
			for(hed__Course_Offering__c corOff : Trigger.new){
				//if(corOff.hed__Course_Enrollment__c != null && corOff.hed__Course_Enrollment__c != Trigger.oldMap.get(corOff.Id).hed__Course_Enrollment__c){
				//	updatesToCourseEnrollment.add(corOff.Id);
				//}

				if(corOff.hed__Course__c != null && corOff.hed__Course__c != Trigger.oldMap.get(corOff.Id).hed__Course__c ||
					corOff.CAUserId__c != null && corOff.CAUserId__c != Trigger.oldMap.get(corOff.Id).CAUserId__c ||
					corOff.FacultyUserID__c != null && corOff.FacultyUserID__c != Trigger.oldMap.get(corOff.Id).FacultyUserID__c){

					insertedOrUpdated.add(corOff.Id);
				}
			}

			//if(!updatesToCourseEnrollment.isEmpty()){
				UpdateSharing = FormulaShareDispatcher.getChangedChildRecords(Trigger.newMap.keySet(), 'hed__Course_Enrollment__c', 'hed__Course_Offering__c');

				if(!UpdateSharing.isEmpty()){
					FormulaShareDispatcher.shareRecords('hed__Course_Enrollment__c', UpdateSharing);
				}
			//}

			if(!insertedOrUpdated.isEmpty()){
				FormulaShareDispatcher.setSharingCourseOffering(insertedOrUpdated);
			}
		}
	}
}