@isTest
public class ScheduledPaymentBatchTest {
@TestSetup
    static void setupTests() {
        Id courseOfferingId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Offering').getRecordTypeId();
        Id courseDevelopersMajorReviewsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Developers & Major Reviews').getRecordTypeId();

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        hed__Course__c course = new hed__Course__c();
        course.Level__c = 'Graduate';
        course.hed__Account__c = testAccount.Id;
        insert course;

        Contact faculty = new Contact();
        faculty.LastName = 'test contact';
        faculty.Faculty_Level__c = 'Standard';
        insert faculty;

        hed__Term__c testTerm = new hed__Term__c();
        testTerm.hed__Account__c = testAccount.Id;
        insert testTerm;

        hed__Course_Offering__c courseOffering = new hed__Course_Offering__c();
        courseOffering.RecordTypeId = courseOfferingId;
        courseOffering.hed__Course__c = course.Id;
        courseOffering.Bi_weekly_payments_start__c = Date.today();
        courseOffering.hed__Term__c = testTerm.Id;
        courseOffering.hed__Faculty__c = faculty.Id;
        courseOffering.Credit_Hours__c = 1;
        courseOffering.Number_of_Students_Registered__c = 6;
        courseOffering.Course_Offering_Type__c = 'Onsite Instruction';
        insert courseOffering;
        
        Payment__c testPayment = new Payment__c();
        testPayment.Course_Offering__c = courseOffering.Id;
        testPayment.Payment_Status__c = 'Scheduled';
        testPayment.Payment_Date__c = System.today() - 1;
        insert testPayment;
    }
    
    @isTest
    static void testBatchSchedulable() 
    {  
        String CRON_EXP = '0 0 0 15 3 ? 2022';        
        Test.startTest();
        String jobId = System.schedule('ScheduledPaymentBatchTest',
                                       CRON_EXP, 
                                       new ScheduledPaymentBatchSchedulable());
        Test.stopTest();
    }
}