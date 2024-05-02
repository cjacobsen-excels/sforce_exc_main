@isTest
private class FormulaShareHelperScheduleTest {

	public static String CRON_EXP = '0 0 0 15 3 ? 2022';
	@isTest
	private static void testName() {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
		insert testContact;

		Formula_Share_Custom__c fs = new Formula_Share_Custom__c(Name = 'test',Formula_Field_API__c = 'CreatedById', isActive__c = true, sObject_API__c ='Account');
		insert fs;

		Formula_Share_Custom__c fs2 = new Formula_Share_Custom__c(Name = 'test2',Formula_Field_API__c = 'OwnerId', isActive__c = true, sObject_API__c ='Account');
		insert fs2;

		Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('FormulaShareHelperSchedule',
            CRON_EXP, 
            new FormulaShareHelperSchedule()); 
		Test.stopTest();
	}

	@isTest
	private static void testName2() {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

		hed__Attribute__c a = new hed__Attribute__c(Name='test', hed__Contact__c = testContact.Id);
		Insert a;

		Formula_Share_Custom__c fs = new Formula_Share_Custom__c(Name = 'test',Formula_Field_API__c = 'hed__Contact__c', isActive__c = true, sObject_API__c ='hed__Attribute__c');
		insert fs;


		Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('FormulaShareHelperSchedule',
            CRON_EXP, 
            new FormulaShareHelperSchedule()); 
		Test.stopTest();
	}
}