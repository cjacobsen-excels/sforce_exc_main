@isTest
public class VerifyCompensationBatchManualTest {
    @TestSetup
    static void setupTests() {
        Id courseOfferingId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Offering').getRecordTypeId();
        Id courseDevelopersMajorReviewsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Developers & Major Reviews').getRecordTypeId();
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        
        hed__Course__c course = new hed__Course__c();
        course.Level__c = 'Upper';
        course.hed__Account__c = testAccount.Id;
        insert course;
        
        Contact faculty = new Contact();
        faculty.LastName = 'test contact';
        faculty.Faculty_Level__c = 'Standard';
        faculty.hed__FERPA__c = true;
        faculty.Faculty_Status__c = 'Active';
        insert faculty;
        
        Custom_Calculation_Date_Offset__c setting = new Custom_Calculation_Date_Offset__c();
        setting.Name = 'Test';
        setting.Days_After_Term_Start__c = 0;
        insert setting;
        
        Training_Assignments__c assignment = new Training_Assignments__c();
        assignment.Faculty_Contact__c = faculty.Id;
        assignment.Training_Type__c = 'FERPA';
        assignment.Status__c = 'Completed';
        assignment.Completed_Date__c = System.today().addDays(-2);
        insert assignment;           
        
        Training_Assignments__c assignment2 = new Training_Assignments__c();
        assignment2.Faculty_Contact__c = faculty.Id;
        assignment2.Training_Type__c = 'Sexual Harrasment';
        assignment2.Status__c = 'Completed';
        assignment2.Completed_Date__c = System.today().addDays(-2);
        insert assignment2; 
        
        Qualified_Faculty__c qualifiedFaculty = new Qualified_Faculty__c();
        qualifiedFaculty.Course__c = course.Id;
        qualifiedFaculty.Faculty__c = faculty.Id;
        insert qualifiedFaculty;
        
        hed__Term__c testTerm = new hed__Term__c();
        testTerm.Name = 'Test';
        testTerm.hed__Account__c = testAccount.Id;
        testTerm.hed__Start_Date__c = Date.today();
        testTerm.hed__End_Date__c = Date.today().addDays(56);
        testTerm.hed__Type__c = 'Term 1';
        insert testTerm;
        
        hed__Term__c testTerm2 = new hed__Term__c();
        testTerm2.Name = 'Test';
        testTerm2.hed__Account__c = testAccount.Id;
        testTerm2.hed__Start_Date__c = Date.today();
        testTerm2.hed__End_Date__c = Date.today().addDays(56);
        testTerm2.hed__Parent_Term__c = testTerm.Id;
        testTerm2.hed__Type__c = 'Term 1';
        insert testTerm2;
        
        hed__Term__c testTerm3 = new hed__Term__c();
        testTerm3.Name = 'Test';
        testTerm3.hed__Account__c = testAccount.Id;
        testTerm3.hed__Start_Date__c = Date.today();
        testTerm3.hed__End_Date__c = Date.today().addDays(56);
        testTerm3.hed__Parent_Term__c = testTerm2.Id;
        testTerm3.hed__Type__c = 'Term 1';
        insert testTerm3;
        
        hed__Course_Offering__c courseOffering = new hed__Course_Offering__c();
        courseOffering.RecordTypeId = courseOfferingId;
        courseOffering.hed__Course__c = course.Id;
        courseOffering.Bi_weekly_payments_start__c = Date.today();
        courseOffering.hed__Term__c = testTerm3.Id;
        courseOffering.Qualified_Faculty__c = qualifiedFaculty.Id;
        courseOffering.Credit_Hours__c = 1;
        courseOffering.Number_of_Students_Registered__c = 6;
        courseOffering.Course_Offering_Type__c = 'Onsite Instruction';
        courseOffering.Status__c = 'Active';
        insert courseOffering;
    }
    
    @isTest
    static void testBatchSchedulable() 
    { 
        List<Id> courseOfferingIds = new List<Id>();
        for (hed__Course_Offering__c courseOffering : [SELECT Id FROM hed__Course_Offering__c]) {
            courseOfferingIds.add(courseOffering.Id);
        }
        
        Test.startTest();
        VerifyCompensationBatchManual manualBatch = new VerifyCompensationBatchManual(courseOfferingIds);
        Database.executeBatch(manualBatch);
        Test.stopTest();
    }
}