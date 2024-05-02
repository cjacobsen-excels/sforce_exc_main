@isTest
private class autoCreateStudentAccountTrigger_Test {
    static testMethod void autoCreateStudentAccountTrigger_Test(){
        RecordType cRecType = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'Person_Account'];   
        Contact testContact = new Contact();
        testContact.FirstName ='Test';
        testContact.LastName = 'Contact';
        testContact.RecordTypeId=cRecType.id;
        
        insert testContact;
        
        Contact testContact2 = [SELECT id, AccountId FROM Contact WHERE Name = 'Test Contact'];
        Account testAccount = [SELECT id, Name FROM Account WHERE Name = 'Test Contact'];
        
        system.assertEquals(testContact2.AccountId,testAccount.id );
        
    }   
}