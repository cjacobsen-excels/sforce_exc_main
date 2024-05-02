trigger CourseConnectionTrigger on hed__Course_Enrollment__c (after insert)  { 
	if(Trigger.isAfter){
		if(Trigger.isInsert){
			List<Id> newCourseEnrollment = new List<Id>();
			for(hed__Course_Enrollment__c ce : Trigger.new){
				newCourseEnrollment.add(ce.Id);
			}

			if(!newCourseEnrollment.isEmpty()){
				CourseConnectionTriggerHandler.insertSharingHelper(newCourseEnrollment);
			}
		}
	}
}