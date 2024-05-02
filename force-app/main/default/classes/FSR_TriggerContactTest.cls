/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
@IsTest(seealldata= true)
public class FSR_TriggerContactTest
{
    public static testMethod void testTrigger()
    {    
		Formula_Share_Custom__c fs = new Formula_Share_Custom__c(Name = 'test',Formula_Field_API__c = 'hed__Contact__c', isActive__c = true, sObject_API__c ='hed__Attribute__c');
		insert fs;

		Contact a = new Contact(LastName='test', Faculty_ID__c = '1234TestClass');
		Insert a;

		a.LastName = 'test2';
		a.Faculty_ID__c = '12345TestClass';
		update a;
    }
}