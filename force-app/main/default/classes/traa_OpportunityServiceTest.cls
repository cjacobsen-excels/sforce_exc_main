@isTest(SeeAllData=true)
public class traa_OpportunityServiceTest {

    @isTest
    static void testOpportunityService() {
        // Use the provided Account ID
        Id providedAccountId = '0014O00002MUmKVQA1';

        // Create a Contact (Applicant)
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe');
        insert testContact;

        // Create an Application using the provided Account ID
        hed__Application__c testApplication = new hed__Application__c(hed__Applicant__c = testContact.Id, hed__Applying_To__c = providedAccountId);
        insert testApplication;

        // Create an open Opportunity for the Applicant using the provided Account ID
        Opportunity existingOpp = new Opportunity(
            Name = 'Existing Opp', 
            traa_Applicant__c = testContact.Id, 
            traa_Academic_Program__c = providedAccountId, 
            StageName = 'Open',
            CloseDate = System.today() + 30,  // Setting CloseDate to a month from now
            Opportunity_Status__c = 'Application Started'  // Setting Opportunity Status
        );
        insert existingOpp;

        // Test method execution
        Test.startTest();
        traa_OpportunityService.createOpportunity(new List<hed__Application__c>{testApplication});
        Test.stopTest();

        // Assertions to ensure code ran
        Opportunity opp = [SELECT Id, Opportunity_Status__c FROM Opportunity WHERE traa_Primary_Application__c = :testApplication.Id LIMIT 1];
        System.assert(opp != null, 'An opportunity should be created or associated with the application.');
        System.assertEquals('Application Started', opp.Opportunity_Status__c, 'Opportunity status should be "Application Started".');

        hed__Application__c updatedApplication = [SELECT Id, traa_Opportunity__c FROM hed__Application__c WHERE Id = :testApplication.Id];
        System.assertEquals(opp.Id, updatedApplication.traa_Opportunity__c, 'Application Opportunity field should be updated.');
    }
}