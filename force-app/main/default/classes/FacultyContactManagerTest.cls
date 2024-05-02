@isTest 
private class FacultyContactManagerTest {

	public static String CRON_EXP = '0 0 0 15 3 ? 2022';
	@isTest
	private static void FacultyContactManagerTestMethod() {
		Contact c = new Contact(Contact_Category__c = 'FC', LastName='test last', FirstName='test first', Manager__c = UserInfo.getUserId(), Last_Hire_Date__c = System.today().addYears(-1).addDays(30));
		insert c;

		Test.startTest();
        // Schedule the test job
		 String jobId = System.schedule('ScheduledApexTest',
            CRON_EXP, 
            new FacultyContactManagerSchedulable());         
        Test.stopTest();

		List<Task> tasks = [SELECT Id, Subject, Description, ActivityDate, OwnerId FROM Task];
		System.debug(tasks);
		//System.assertEquals(tasks.Size(),1);
	}

	@isTest
	private static void FacultyContactManagerTestBatchMethod() {
		Contact c = new Contact(Contact_Category__c = 'FC', LastName='test last', FirstName='test first', Manager__c = UserInfo.getUserId(), Last_Hire_Date__c = System.today().addYears(-3).addDays(30));
		insert c;

		Test.startTest();
        FacultyContactManagerBatchable fcmb = new FacultyContactManagerBatchable();
		Database.executeBatch(fcmb,200);      
        Test.stopTest();

		List<Task> tasks = [SELECT Id, Subject, Description, ActivityDate, OwnerId FROM Task];
		System.debug(tasks);
		//System.assertEquals(tasks.Size(),1);
	}
}