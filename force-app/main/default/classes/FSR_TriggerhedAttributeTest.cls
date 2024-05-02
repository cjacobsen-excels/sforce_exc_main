/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
@IsTest(seealldata= true)
public class FSR_TriggerhedAttributeTest
{
    public static testMethod void testTrigger()
    {
		Formula_Share_Custom__c fs = new Formula_Share_Custom__c(Name = 'test',Formula_Field_API__c = 'hed__Contact__c', isActive__c = true, sObject_API__c ='hed__Attribute__c');
		insert fs;

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

		a.hed__Contact__c = testContact2.Id;
		update a;
    }
}