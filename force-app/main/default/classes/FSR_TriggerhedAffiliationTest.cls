/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
@IsTest(seealldata= true)
public class FSR_TriggerhedAffiliationTest
{
    public static testMethod void testTrigger()
    {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

		hed__Affiliation__c a = new hed__Affiliation__c(hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id);
		Insert a;

		a.hed__Contact__c = testContact2.Id;
		update a;
    }
}