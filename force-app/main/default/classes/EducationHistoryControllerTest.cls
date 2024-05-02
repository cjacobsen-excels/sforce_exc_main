/**
* Created by mnahar on 23/06/21.
*/

@isTest
public class EducationHistoryControllerTest {

    @isTest
    private static void getEducationHistoryRecordsTest() {
        UserRole userRole_1 = [SELECT Id FROM UserRole LIMIT 1];
        Profile profile_1 = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Contact contact_1 = new Contact(LastName = 'xgeek');
        insert contact_1;

        User user_1 = new User(
                Email = 'yourusername@gmail.com',
                ProfileId = profile_1.Id,
                Username = 'yourusername@gmail.comtraa',
                Alias = 'Test',
                TimeZoneSidKey = 'America/New_York',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ContactId = contact_1.Id,
                FirstName = 'Firstname',
                LastName = 'Lastname'
        );
        insert user_1;

        hed__Application__c progApp = new hed__Application__c(traa_Required_Items_Remaining__c = 7, hed__Applicant__c = contact_1.Id);
        insert progApp;

        Id appEdRecTypeId = Schema.SObjectType.traa_Educational_History__c.getRecordTypeInfosByName().get('Credential').getRecordTypeId();
        traa_Educational_History__c test_Educational_History = new traa_Educational_History__c (
                traa_Application__c = progApp.Id,
                RecordTypeId = appEdRecTypeId
        );
        insert test_Educational_History;

        List<traa_Educational_History__c> historyRecords ;
        Test.startTest();
        System.runAs(user_1) {
            historyRecords = EducationHistoryController.getEducationHistoryRecords();
        }
        Test.stopTest();

        System.assert(historyRecords != null, 'No Education History records retrieved');
    }
}