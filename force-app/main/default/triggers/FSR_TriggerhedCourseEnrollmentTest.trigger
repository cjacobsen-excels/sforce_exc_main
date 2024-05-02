Trigger FSR_TriggerhedCourseEnrollmentTest on hed__Course_Enrollment__c(after insert, after update){
	System.debug('hed__Course_Enrollment__c Trigger');
    if(Trigger.isAfter){
		Set<Id> UpdateSharing = new Set<Id>();
		if(Trigger.isInsert){
			FormulaShareDispatcher.shareRecords('hed__Course_Enrollment__c', trigger.newMap.keySet());
		}

		if(Trigger.isUpdate){
			UpdateSharing = FormulaShareDispatcher.getChangedRecords(Trigger.new, Trigger.oldMap, 'hed__Course_Enrollment__c');

			if(!UpdateSharing.isEmpty()){
				FormulaShareDispatcher.shareRecords('hed__Course_Enrollment__c', UpdateSharing);
			}
		}
	}
}