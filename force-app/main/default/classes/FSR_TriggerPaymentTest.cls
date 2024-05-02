/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
@IsTest(seealldata= true)
public class FSR_TriggerPaymentTest
{
    public static testMethod void testTrigger()
    {

		Contact testContact2= new Contact();
        testContact2.LastName= 'testlast2';
        insert testContact2;

		Payment__c Pay = new Payment__c(Payment_Status__c='Scheduled');
		Insert Pay;

		Pay.Pay_To__c = testContact2.Id;
		update Pay;
    }
}