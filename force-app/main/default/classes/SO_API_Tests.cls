/**
 * @author Ed Montalbano
 * @date 11-22-2019
 *
 * @group Test Code
 *
 * @description This class contains a collection of tests for the API and data 
 * access layer.
**/
@isTest
public class SO_API_Tests {
  
  @TestSetup
  private static void setup() {
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='excelsiorTestUser@email.com', 
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = p.Id, 
                        TimeZoneSidKey='America/Los_Angeles', UserName='excelsiorTestUser@email.com');
    insert u;      
  }
    
  @isTest
  public static void testGetAll() {
    User u = [SELECT Id FROM User LIMIT 1]; 

    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a.Name = 'Test';
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    Account a2 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a2.Name = 'Test 2';
    //a2.forcebrain__IsPersonalAccount__c = true;
    //a2.forcebrain__IsProvider__c = false;
    a2.OwnerId = u.Id;
    Account a3 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a3.Name = 'Test 3';
    //a3.forcebrain__IsPersonalAccount__c = true;
    //a3.forcebrain__IsProvider__c = false;
    a3.OwnerId = u.Id;
    Account[] accounts = new Account[]{
      a, a2, a3
    };
    insert accounts;
    
    SO_ViewModel model = new SO_ViewModel();
    model.query = new SO_ViewModel.Query();
    model.query.sObjectType = 'Account';
    model.query.fields = new String[]{ 'Id', 'Name' };
    
    String result = SO_API.getAll( JSON.serialize(model) );
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );
    System.assertEquals(3, m2.data.items.size());
    
  }
  
  
  @isTest
  public static void testRawQuery() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a.Name = 'Test';
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    insert a;
    Account a2 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});    
    a2.Name = 'Test';
    a2.ParentId = a.Id;
    //a2.forcebrain__IsPersonalAccount__c = true;
    //a2.forcebrain__IsProvider__c = false;
    a2.OwnerId = u.Id;
    Account a3 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a3.Name = 'Test';
    a3.ParentId = a.Id;
    //a3.forcebrain__IsPersonalAccount__c = true;
    //a3.forcebrain__IsProvider__c = false;
    a3.OwnerId = u.Id;
    insert new Account[]{a2, a3};
    
    SO_ViewModel model = new SO_ViewModel();
    model.query = new SO_ViewModel.Query();
    model.query.rawQuery = 'SELECT Id, Name, Parent.Name FROM Account';
    
    String result = SO_API.getAll( JSON.serialize(model) );
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );
    System.assertEquals(3, m2.data.items.size());    
  }

  @isTest
  public static void testMultiQuery() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a.Name = 'Test';      
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    insert a;
    Account a2 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});    
    a2.Name = 'Test';
    a2.ParentId = a.Id;      
    //a2.forcebrain__IsPersonalAccount__c = true;
    //a2.forcebrain__IsProvider__c = false;
    a2.OwnerId = u.Id;
    Account a3 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a3.Name = 'Test';
    a3.ParentId = a.Id;      
    //a3.forcebrain__IsPersonalAccount__c = true;
    //a3.forcebrain__IsProvider__c = false;
    a3.OwnerId = u.Id;
    insert new Account[]{a2, a3};
    
    Contact c = (Contact)SO_TestUtil.populateNewObject('Contact');
    c.AccountId = a.Id; 
    c.OwnerId = u.Id;
    //c.forcebrain__User__c = u.Id;
    //c.forcebrain__IsProvider__c = false;
    //c.forcebrain__IsPersonalAccount__c = true;
    insert c;
    
    SO_ViewModel model = new SO_ViewModel();
    SO_ViewModel.Query q1 = new SO_ViewModel.Query();
    q1.rawQuery = 'SELECT Id, Name, Parent.Name FROM Account';
    SO_ViewModel.Query q2 = new SO_ViewModel.Query();
    q2.rawQuery = 'SELECT Id, FirstName, LastName FROM Contact';
    model.queries = new SO_ViewModel.Query[]{ q1, q2 };
    
    String result = SO_API.getAll( JSON.serialize(model) );
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );
    System.assertEquals(4, m2.data.items.size());
  }
    
  
  @isTest
  public static void createRecords() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    SO_ViewModel model = new SO_ViewModel();
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    model.data.items = new SO_ViewModel.sObjectListItem[]{};
    SO_ViewModel.sObjectListItem li = new SO_ViewModel.sObjectListItem();
    li.value = a;
    li.modified = true;
    model.data.items.add(li);
    String result = SO_API.upsertAll(JSON.serialize(model), true);
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );

    model.data.items[0].toDelete = true;
    String result2 = SO_API.upsertAll(JSON.serialize(model), true);
    SO_ViewModel m3 = SO_API.deserializeViewModel( result2 );
  }

  @isTest
  public static void deleteOnUpsert() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    SO_ViewModel model = new SO_ViewModel();
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    insert a;
    model.data.items = new SO_ViewModel.sObjectListItem[]{};
    SO_ViewModel.sObjectListItem li = new SO_ViewModel.sObjectListItem();
    li.value = a;
    li.modified = true;
    li.toDelete = true;
    model.data.items.add(li);
    String result2 = SO_API.upsertAll(JSON.serialize(model), true);
    SO_ViewModel m3 = SO_API.deserializeViewModel( result2 );
  }

  @isTest
  public static void deleteRecords() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    SO_ViewModel model = new SO_ViewModel();
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    insert a;
    model.data.items = new SO_ViewModel.sObjectListItem[]{};
    SO_ViewModel.sObjectListItem li = new SO_ViewModel.sObjectListItem();
    li.value = a;
    li.modified = true;
    li.toDelete = true;
    model.data.items.add(li);
    String result = SO_API.deleteAll(JSON.serialize(model), true);
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );
  }

  @isTest
  public static void testSubQuery() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a.Name = 'Test';      
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    Account a2 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a2.Name = 'Test 2';      
    //a2.forcebrain__IsPersonalAccount__c = true;
    //a2.forcebrain__IsProvider__c = false;
    a2.OwnerId = u.Id;
    Account a3 = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a3.Name = 'Test 3';
    //a3.forcebrain__IsPersonalAccount__c = true;
    //a3.forcebrain__IsProvider__c = false;
    a3.OwnerId = u.Id;
    Account[] accounts = new Account[]{
      a, a2, a3
    };
    insert accounts;

    Contact c = (Contact)SO_TestUtil.populateNewObject('Contact');
    c.AccountId = a.Id;
    c.OwnerId = u.Id;
    //c.forcebrain__User__c = u.Id;
    insert c;
    
    SO_ViewModel model = new SO_ViewModel();
    model.query = new SO_ViewModel.Query();
    model.query.sObjectType = 'Account';
    model.query.fields = new String[]{ 'Id', 'Name as nom' };

    model.query.subQueries = new List<SO_ViewModel.Query>();
    SO_ViewModel.Query sq = new SO_ViewModel.Query();
    sq.rawQuery = 'SELECT Id, Name, AccountId FROM Contact WHERE AccountId = \'$PARENT.Id\'';
    model.query.subQueries.add(sq);
    
    String result = SO_API.getAll( JSON.serialize(model) );
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );
    System.assertEquals(3, m2.data.items.size());
    
  }

  @isTest
  public static void testAggregate() {
    User u = [SELECT Id FROM User LIMIT 1]; 
    Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
    a.Name = 'Test';
    //a.forcebrain__IsPersonalAccount__c = true;
    //a.forcebrain__IsProvider__c = false;
    a.OwnerId = u.Id;
    Account[] accounts = new Account[]{
      a
    };
    insert accounts;

    Contact c = (Contact)SO_TestUtil.populateNewObject('Contact');
    c.AccountId = a.Id;
    //c.forcebrain__IsProvider__c = false;
    //c.forcebrain__IsPersonalAccount__c = true;
    insert c;
    
    SO_ViewModel model = new SO_ViewModel();
    model.query = new SO_ViewModel.Query();
    model.query.sObjectType = 'Account';
    model.query.fields = new String[]{ 'Id', 'Name as nom' };

    model.query.subQueries = new List<SO_ViewModel.Query>();
    SO_ViewModel.Query sq = new SO_ViewModel.Query();
    sq.rawQuery = 'SELECT Id, Name, AccountId FROM Contact WHERE AccountId = \'$THIS.Id\'';
    model.query.subQueries.add(sq);
    
    String result = SO_API.getAll( JSON.serialize(model) );
    SO_ViewModel m2 = SO_API.deserializeViewModel( result );
    System.assertEquals(1, m2.data.items.size());
    
  }
    
    @isTest public static void testSearchAll() {
    User u = [SELECT Id FROM User LIMIT 1]; 
        Account a = (Account)SO_TestUtil.populateNewObject('Account', new String[]{}, new String[]{});
        a.Name = 'Test';
    a.OwnerId = u.Id;
        
      //a.forcebrain__IsPersonalAccount__c = true;
      //a.forcebrain__IsProvider__c = false;
        Account[] accounts = new Account[]{
          a
        };
        insert accounts;
        
        String result = SO_API.searchAll('Account', 'est', 'Name,BillingAddress');
    }

}