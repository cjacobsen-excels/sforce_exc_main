public class CourseConnectionTriggerHandler  {

	public static void insertSharingHelper(List<Id> courseIdLst){
		Map<Id,Set<Id>> existingShares = new Map<Id,Set<Id>>();
		Map<Id,hed__Course_Enrollment__c> existingCourseEnrollment = new Map<Id,hed__Course_Enrollment__c>();
		List<ContactShare> newConShares = new List<ContactShare>();
		List<Id> faciltyContactId = new List<Id>();

		System.Debug(courseIdLst);
		for(hed__Course_Enrollment__c ce : [SELECT Id, hed__Contact__c, hed__Course_Offering__r.FPD__c, 
													hed__Course_Offering__r.Status__c FROM hed__Course_Enrollment__c 
													WHERE Id IN: courseIdLst AND hed__Course_Offering__r.Status__c != 'Completed']){
			existingCourseEnrollment.put(ce.Id, ce);
			faciltyContactId.add(ce.hed__Course_Offering__r.FPD__c);
		}

		for(ContactShare cs : [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE UserOrGroupId IN: faciltyContactId]){
			if (existingShares.containsKey(cs.UserOrGroupId) && existingShares.get(cs.UserOrGroupId) != null) {
	            Set<Id> conShar = existingShares.get(cs.UserOrGroupId);
	            conShar.add(cs.ContactId);
	            existingShares.put(cs.UserOrGroupId, conShar);
	        }
	        else {
	            existingShares.put(cs.UserOrGroupId, new Set<Id> { cs.ContactId });
	        }
		}

		System.Debug(existingCourseEnrollment.keySet());
		for(Id se : existingCourseEnrollment.keySet()){
			hed__Course_Enrollment__c courseEnrollment = existingCourseEnrollment.get(se);
			System.Debug(courseEnrollment);
			if(courseEnrollment != null){
				Set<Id> existingStudentShares = new Set<Id>();
				existingStudentShares = existingShares.get(courseEnrollment.hed__Course_Offering__r.FPD__c);
				System.Debug(existingStudentShares);
				if(existingStudentShares == null || !existingStudentShares.contains(courseEnrollment.hed__Contact__c)){
					newConShares.add(ShareRecordHandler.createShare(courseEnrollment.hed__Contact__c, courseEnrollment.hed__Course_Offering__r.FPD__c));
				}
			}
		}

		System.Debug(newConShares);
		if(!newConShares.isEmpty()){
			//insert newConShares;
			Database.insert(newConShares,false);
		}
	}
}