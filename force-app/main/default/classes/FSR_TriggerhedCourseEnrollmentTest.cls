/**
 * Auto Generated and Deployed by the Formula Sharing
 **/
@IsTest(seealldata= true)
public class FSR_TriggerhedCourseEnrollmentTest
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
        testContact2.LastName= 'testlast2';
        insert testContact2;
        
        hed__Course__c course = new hed__Course__c();
        course.hed__Account__c = testAccount.Id;
        course.name= 'test';
        insert course;
        
        hed__Term__c term = new hed__Term__c(Name = 'test', hed__Account__c = testAccount.Id);
        insert term;
        
        hed__Course_Offering__c corOff = new hed__Course_Offering__c(Name = 'test', hed__Term__c = term.Id, hed__Course__c = course.Id);
        insert corOff;
        
        hed__Course_Enrollment__c corCON = new hed__Course_Enrollment__c(hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, hed__Course_Offering__c = corOff.Id);
        insert corCON;

		corCON.hed__Contact__c = testContact2.Id;
		Update corCON;
    }
}