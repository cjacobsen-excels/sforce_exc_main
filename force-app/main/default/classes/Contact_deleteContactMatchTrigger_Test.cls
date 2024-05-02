@isTest
private class Contact_deleteContactMatchTrigger_Test {
    static testMethod void Contact_deleteContactMatchTrigger_Test(){
        RecordType cRecType =[SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'Person_Account'];
        Contact testContact1 = new Contact();
        testContact1.FirstName = 'Test1';
        testContact1.LastName = 'Contact1';
        testContact1.Email='Test1@test.com';
        testContact1.RecordTypeId = cRecType.id;
        
        insert testContact1;
        Contact_Match__c[] cm1 = [SELECT Match_Key__c FROM Contact_Match__c WHERE Contact_Id__c = :testContact1.Id];
        if (cm1.size() >0)
            system.assertEquals('TEST1CONTACT1TEST1@TEST.COM', cm1[0].Match_Key__c);
        
        Contact testContact2 = new Contact();
        testContact2.FirstName = 'Test2';
        testContact2.LastName = 'Contact2';
        testContact2.Email='Test2@test.com';
        testContact2.RecordTypeId = cRecType.id;
        
        insert testContact2;
        Contact_Match__c[] cm2 = [SELECT Match_Key__c FROM Contact_Match__c WHERE Contact_Id__c = :testContact2.Id];
        if (cm2.size() >0)
            system.assertEquals('TEST2CONTACT2TEST2@TEST.COM', cm2[0].Match_Key__c);
        
        database.merge(testContact1, testContact2);
        
        List<Contact_Match__c> cm = [SELECT Match_Key__c FROM Contact_Match__c]; 
        system.assertEquals(1, cm.size());  
        system.debug(cm[0].Match_Key__c);
    }
}