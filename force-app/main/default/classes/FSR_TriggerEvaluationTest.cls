/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
 @isTest
public class FSR_TriggerEvaluationTest
{
    public static testMethod void testTrigger()
    {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;
	
		Contact c = new Contact(LastName='test', Faculty_ID__c = '1234TestClass');
		Insert c;

		Evaluation__c a = new Evaluation__c();
		Insert a;
	
		a.Faculty_Member__c = c.Id;
		update a;
    }
}