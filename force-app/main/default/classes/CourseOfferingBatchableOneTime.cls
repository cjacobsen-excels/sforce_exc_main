global class CourseOfferingBatchableOneTime implements Database.Batchable<SObject> {
	
	global String shareUser;
	global CourseOfferingBatchableOneTime(String shareUser) {
		this.shareUser = shareUser;
	}
	
	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator('SELECT Id, Name,CreatedById FROM hed__Course_Offering__c WHERE CreatedById =: shareUser');
	}

   	global void execute(Database.BatchableContext context, List<hed__Course_Offering__c> scope) {
		Set<Id> insertedOrUpdated = new Set<Id>();
		for(hed__Course_Offering__c s: scope){
			insertedOrUpdated.add(s.Id);
		}

		FormulaShareDispatcher.setSharingCourseOffering(insertedOrUpdated);
	}

	global void finish(Database.BatchableContext context) {
		
	}
}