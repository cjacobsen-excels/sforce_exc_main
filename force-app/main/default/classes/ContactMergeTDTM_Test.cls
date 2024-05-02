/**
 * Created by mnahar on 22/06/21.
 */

@IsTest
private class ContactMergeTDTM_Test {
    
    @IsTest
    static void testContactMerge() {
        //Retrieve default EDA trigger handlers
        List<hed.TDTM_Global_API.TdtmToken> tokens = hed.TDTM_Global_API.getTdtmConfig();
        //Create trigger handler using the constructor
        tokens.add(new hed.TDTM_Global_API.TdtmToken('ContactMergeTDTM', 'Contact', 'AfterDelete', 1.00));
        // Pass trigger handler config to set method for this test run
        hed.TDTM_Global_API.setTdtmConfig(tokens);

        //Create Student Records
        Id recordTypeIdCon = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Person_Account').getRecordTypeId();
        List<Contact> duplicateContacts = new  List<Contact>();
        Contact student1 = new Contact();
        student1.RecordTypeId = recordTypeIdCon;
        student1.FirstName = 'Jennifer';
        student1.LastName = 'Stark';
        student1.Email = 'jenny@stark.com';
        duplicateContacts.add(student1);

        Contact student2 = new Contact();
        student2.RecordTypeId = recordTypeIdCon;
        student2.FirstName = 'Jen';
        student2.LastName = 'Stark';
        student2.Email = 'jenny@stark.com';
        duplicateContacts.add(student2);

        insert  duplicateContacts;

        Test.startTest();
        //Merge Contacts
        merge student1 student2;
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(contacts.size(), 1, 'Contacts were not merged');

        List<Contact_Merge_History__c> contactHistory = [SELECT Id FROM Contact_Merge_History__c];
        System.assertEquals(contactHistory.size(), 1, 'Contact history record not created');
    }
}