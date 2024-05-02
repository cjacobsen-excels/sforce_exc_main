/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
@IsTest
public class FSR_TriggerhedCourseOfferingTest
{
    public static testMethod void testTrigger()
    {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact a = new Contact(LastName='test', Faculty_ID__c = '1234TestClass', Faculty_User_Record__c = UserInfo.getUserId());
		Insert a;

		hed__Course__c course = new hed__Course__c();
		course.hed__Account__c = testAccount.Id;
		course.name= 'test';
		insert course;

		hed__Term__c term = new hed__Term__c(Name = 'test', hed__Account__c = testAccount.Id);
		insert term;

		hed__Course_Offering__c corOff = new hed__Course_Offering__c(Clinical_Associate__c = a.Id, Name = 'test', hed__Term__c = term.Id, hed__Course__c = course.Id);
		insert corOff;

		corOff.Name = 'test2';
		update corOff;
    }

	public static testMethod void testTrigger2()
    {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact a = new Contact(LastName='test', Faculty_ID__c = '1234TestClass', Faculty_User_Record__c = UserInfo.getUserId());
		Insert a;

		hed__Course__c course = new hed__Course__c();
		course.hed__Account__c = testAccount.Id;
		course.name= 'test';
		insert course;

		hed__Term__c term = new hed__Term__c(Name = 'test', hed__Account__c = testAccount.Id);
		insert term;

		hed__Course_Offering__c corOff = new hed__Course_Offering__c(hed__Faculty__c = a.Id, Name = 'test', hed__Term__c = term.Id, hed__Course__c = course.Id);
		insert corOff;

		corOff.Name = 'test2';
		update corOff;
    }

	public static testMethod void testTrigger3()
    {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact a = new Contact(LastName='test', Faculty_ID__c = '1234TestClass', Faculty_User_Record__c = UserInfo.getUserId());
		Insert a;

		hed__Course__c course = new hed__Course__c();
		course.hed__Account__c = testAccount.Id;
		course.name= 'test';
		insert course;

		hed__Term__c term = new hed__Term__c(Name = 'test', hed__Account__c = testAccount.Id);
		insert term;

		hed__Course_Offering__c corOff = new hed__Course_Offering__c(Name = 'test', hed__Term__c = term.Id, hed__Course__c = course.Id);
		insert corOff;

		corOff.Name = 'test2';
		update corOff;
    }
}