@isTest
public class CourseConnectionTriggerHandlerTest {
	static testmethod void testSch(){
        Account a =new Account(Name= 'test');
        insert a;
        
        Contact c = new Contact(LastName='FacTest1', Faculty_ID__c = 'testId1');
        insert c;
        
        Contact c2 = new Contact(AccountId = a.id, LastName='stu');
        insert c2;
        
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Faculty']; 
        User u = new User(Alias = 'standt', Email='standarduser123123@test21323org.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardus213123er@tes12312312torg.com',
            Faculty_ID__c = 'testId1');
        
        hed__Course__c course = new hed__Course__c();
        course.hed__Account__c = a.Id;
        course.name= 'test';
        insert course;
        
        hed__Term__c term = new hed__Term__c(Name = 'test', hed__Account__c = a.Id);
        insert term;
        
        hed__Course_Offering__c corOff = new hed__Course_Offering__c(FPD__c = u.Id, Status__c = 'Active', Name = 'test', hed__Term__c = term.Id, hed__Course__c = course.Id);
        insert corOff;
        
        hed__Course_Enrollment__c cr = new hed__Course_Enrollment__c(hed__Account__c = a.Id, 
              hed__Contact__c = c2.Id, hed__Course_Offering__c = corOff.Id);
        insert cr;
        
        List<ContactShare> cs = [SELECT id, ContactId FROM ContactShare WHERE ContactId =: c2.Id];
        System.assertEquals(2, cs.size());
    }

	static testmethod void testOneTimeBatch(){
		Account a =new Account(Name= 'test');
        insert a;
        
        Contact c = new Contact(LastName='FacTest1', Faculty_ID__c = 'testId1');
        insert c;
        
        Contact c2 = new Contact(AccountId = a.id, LastName='stu');
        insert c2;

		 Profile p = [SELECT Id FROM Profile WHERE Name='Faculty']; 
        User u = new User(Alias = 'standt', Email='standarduser123123@test21323org.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardus213123er@tes12312312torg.com',
            Faculty_ID__c = 'testId1');

		hed__Course__c course = new hed__Course__c();
        course.hed__Account__c = a.Id;
        course.name= 'test';
        insert course;
        
        hed__Term__c term = new hed__Term__c(Name = 'test', hed__Account__c = a.Id);
        insert term;
        
        hed__Course_Offering__c corOff = new hed__Course_Offering__c(FPD__c = u.Id, Status__c = 'Active', Name = 'test', hed__Term__c = term.Id, hed__Course__c = course.Id);
        insert corOff;
        
        hed__Course_Enrollment__c cr = new hed__Course_Enrollment__c(hed__Account__c = a.Id, 
              hed__Contact__c = c2.Id, hed__Course_Offering__c = corOff.Id);
        insert cr;

		CourseOfferingBatchableOneTime coOneTime = new CourseOfferingBatchableOneTime(UserInfo.getUserId());
		Database.executeBatch(coOneTime,10);
	}
}