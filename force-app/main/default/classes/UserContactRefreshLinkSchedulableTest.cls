@isTest 
private class UserContactRefreshLinkSchedulableTest {
	
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';

	@isTest
	private static void testMainExacute() {
		Formula_Share_Custom__c fs = new Formula_Share_Custom__c(Name = 'test',Formula_Field_API__c = 'hed__Contact__c', isActive__c = true, sObject_API__c ='hed__Attribute__c');
		insert fs;

		Contact a = new Contact(LastName='test', Faculty_ID__c = '1234TestClass');
		Insert a;

		User u = [SELECT Id,Faculty_ID__c FROM User WHERE Id =: UserInfo.getUserId()];
		u.Faculty_ID__c = '1234TestClass';

		update u;

		Test.startTest();
        String jobId = System.schedule('UserContactRefreshLinkSchedulable',
            CRON_EXP, 
            new UserContactRefreshLinkSchedulable());         
        Test.stopTest();


	}
}