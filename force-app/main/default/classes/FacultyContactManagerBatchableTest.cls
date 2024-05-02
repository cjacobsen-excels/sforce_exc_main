@isTest 
private class FacultyContactManagerBatchableTest {
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';
	@isTest
	private static void testScheduleTest() {
		Date newDate = Date.newInstance(2022,3,15);
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
		testContact.Contact_Category__c = 'FC';
		testContact.Manager__c = UserInfo.getUserId();
		testContact.Last_Hire_Date__c = newDate.addDays(30).addYears(-1);
		insert testContact;

		Test.startTest();
        String jobId = System.schedule('testClassforFacultyContactManagerBatchable1234',
            CRON_EXP, 
            new FacultyContactManagerSchedulable()); 
		Test.stopTest();
	}

	@isTest
	private static void testBatchTest() {
		Date newDate = System.today().addDays(30).addYears(-1);
		System.debug(newDate);
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
		testContact.Contact_Category__c = 'FC';
		testContact.Manager__c = UserInfo.getUserId();
		testContact.Last_Hire_Date__c = newDate;
		insert testContact;

		Test.startTest();
        FacultyContactManagerBatchable fcmb = new FacultyContactManagerBatchable();
		Database.executeBatch(fcmb,200);
		Test.stopTest();

		List<Task> tasks = [SELECT Id FROM Task];
		System.assertNotEquals(tasks.size(), 0);
	}
}