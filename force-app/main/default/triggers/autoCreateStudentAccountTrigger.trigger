trigger autoCreateStudentAccountTrigger on Contact (after insert) {
    RecordType aRecType = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND DeveloperName = 'Student_Account'];
    RecordType cRecType = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'Person_Account'];   
    Id integrationUserId = [SELECT Id FROM User WHERE Alias = 'iuser'].Id;
    Id MarketoUserId = [SELECT Id FROM User WHERE Alias = 'MKTO'].Id;
       
    Map<Id, Account> aMap = new Map<Id, Account>();
    
    for (Contact con : trigger.new){
        if(con.AccountID == null && con.RecordTypeId == cRecType.Id && con.CreatedById !=MarketoUserId){
            Account acc = new Account();
                acc.name = con.FirstName + ' ' + con.LastName ;
                acc.RecordTypeId = aRecType.Id;
            aMap.put(con.Id, acc);
        }
    }

    if (!aMap.isEmpty()) {
        insert aMap.values();

        List<Contact> cList = new List<Contact>();

        for (Id cId : aMap.keySet()) {
            Contact con = new Contact();
                con.Id = cId;
                con.AccountId = aMap.get(cId).Id;
            cList.add(con);
        }

        update cList;

    }
}