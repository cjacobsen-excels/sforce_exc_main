/**
 * Created by MylesVerigin on 2021-11-04.
 */

@IsTest(SeeAllData=true)
private class ContactAffiliation_TDTMTest {

    @IsTest
    static void testContactAffiliation_TDTM_notFromCommunity() {
        setupData();

        User u = [
                SELECT Id,ContactId, Contact.Acad_Corp_Part_Ref__c
                FROM User
                WHERE UserName = 'standardus213123er@tes12312312torg.com'
        ];
        Id partnerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account partnerAcc = [
                SELECT Id
                FROM Account
                WHERE RecordTypeId =: partnerId
                AND POP_Code__c != null
                AND Id != :u.Contact.Acad_Corp_Part_Ref__c
                LIMIT 1
        ];
        Contact contactToUpdate = [
                SELECT Id
                FROM Contact
                WHERE Id=:u.ContactId
        ];
        contactToUpdate.Acad_Corp_Part_Ref__c = partnerAcc.Id;

        List<hed__Affiliation__c> startingData;
        List<hed__Affiliation__c> endingData;
        Test.startTest();
        startingData = [
                SELECT Id
                FROM hed__Affiliation__c
                WHERE hed__Contact__c =: contactToUpdate.Id
        ];
        update contactToUpdate;
        endingData = [
                SELECT Id
                FROM hed__Affiliation__c
                WHERE hed__Contact__c =: contactToUpdate.Id
        ];
        Test.stopTest();

        System.assertEquals(startingData.size(), endingData.size(),'Expected no new affiliations');
    }

    @IsTest
    static void testContactAffiliation_TDTM_fromCommunity() {
        setupData();

        User u = [
                SELECT Id,ContactId, Contact.Acad_Corp_Part_Ref__c
                FROM User
                WHERE UserName = 'standardus213123er@tes12312312torg.com'
        ];
        Id partnerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account partnerAcc = [
                SELECT Id
                FROM Account
                WHERE RecordTypeId =: partnerId
                AND POP_Code__c != null
                AND Id != :u.Contact.Acad_Corp_Part_Ref__c
                LIMIT 1
        ];
        Contact contactToUpdate = [
                SELECT Id
                FROM Contact
                WHERE Id=:u.ContactId
        ];
        contactToUpdate.Acad_Corp_Part_Ref__c = partnerAcc.Id;
        contactToUpdate.Changed_in_Community__c = true;

        List<hed__Affiliation__c> startingData;
        List<hed__Affiliation__c> endingData;
        Test.startTest();
        startingData = [
                SELECT Id
                FROM hed__Affiliation__c
                WHERE hed__Contact__c =: contactToUpdate.Id
        ];
        update contactToUpdate;
        endingData = [
                SELECT Id
                FROM hed__Affiliation__c
                WHERE hed__Contact__c =: contactToUpdate.Id
        ];
        Test.stopTest();
        Contact resultingContact = [
                SELECT Changed_in_Community__c
                FROM Contact
                WHERE Id = :contactToUpdate.Id
        ];

        System.assertNotEquals(startingData.size(), endingData.size(),'Expected new affiliations because change came from community');
        System.assertEquals(false, resultingContact.Changed_in_Community__c,'changed in community not set back to false');
    }
    @IsTest
    static void testContactAffiliation_TDTM_existingAffiliation() {
        setupData();

        User u = [
                SELECT Id,ContactId, Contact.Acad_Corp_Part_Ref__c
                FROM User
                WHERE UserName = 'standardus213123er@tes12312312torg.com'
        ];
        Id partnerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account partnerAcc = [
                SELECT Id
                FROM Account
                WHERE RecordTypeId =: partnerId
                AND POP_Code__c != null
                AND Id != :u.Contact.Acad_Corp_Part_Ref__c
                LIMIT 1
        ];
        Contact contactToUpdate = [
                SELECT Id
                FROM Contact
                WHERE Id=:u.ContactId
        ];

        // create affiliation with account before insert
        Id partnerAffiliationId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get(traa_Constants.AFFILIATION_RECORD_NAME).getRecordTypeId();
        hed__Affiliation__c newAffiliation = new hed__Affiliation__c(
                hed__Account__c = partnerAcc.Id,
                hed__Contact__c = contactToUpdate.Id,
                hed__Primary__c = true,
                RecordTypeId = partnerAffiliationId
        );
        insert newAffiliation;

        contactToUpdate.Acad_Corp_Part_Ref__c = partnerAcc.Id;
        contactToUpdate.Changed_in_Community__c = true;

        List<hed__Affiliation__c> startingData;
        List<hed__Affiliation__c> endingData;
        Test.startTest();
        startingData = [
                SELECT Id
                FROM hed__Affiliation__c
                WHERE hed__Contact__c =: contactToUpdate.Id
        ];
        update contactToUpdate;
        endingData = [
                SELECT Id
                FROM hed__Affiliation__c
                WHERE hed__Contact__c =: contactToUpdate.Id
        ];
        Test.stopTest();
        Contact resultingContact = [
                SELECT Changed_in_Community__c
                FROM Contact
                WHERE Id = :contactToUpdate.Id
        ];

        System.assertEquals(startingData.size(), endingData.size(),'Expected no new affiliations to be created user already has them');
        System.assertEquals(false, resultingContact.Changed_in_Community__c,'changed in community not set back to false');
    }

    private static void setupData () {
        List<hed.TDTM_Global_API.TdtmToken> tokens = hed.TDTM_Global_API.getTdtmConfig();
        tokens.add(new hed.TDTM_Global_API.TdtmToken('ContactAffiliation_TDTM', 'Contact',  'BeforeUpdate', 10.00));
        hed.TDTM_Global_API.setTdtmConfig(tokens);

        Id partnerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        List<Account> partnerAcc = [
                SELECT Id
                FROM Account
                WHERE RecordTypeId =: partnerId
                AND POP_Code__c != null
                LIMIT 1
        ];

        Contact newContact = new Contact(
                FirstName = 'APEX',
                LastName = 'TESTCONTACT',
                Acad_Corp_Part_Ref__c = partnerAcc.get(0).Id
        );
        insert newContact;

        Profile p = [
                SELECT Id
                FROM Profile
                WHERE Name = :traa_Constants.COMMUNITY_PROFILE
        ];

        User u = new User(
                Alias = '4321',
                Email = 'standarduser123123@test21323org.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'standardus213123er@tes12312312torg.com',
                ContactId = newContact.Id
        );

        User admin = [
                SELECT Id
                FROM User
                WHERE Profile.Name = 'System Administrator'
                AND IsActive = true
                LIMIT 1
        ];

        System.runAs(admin){
            insert u;
        }
    }

}