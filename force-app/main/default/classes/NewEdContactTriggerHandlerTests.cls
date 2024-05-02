@isTest
private class NewEdContactTriggerHandlerTests {
	
	@isTest static void testDupeMergeNewContact() {
		
		NewEd__Contact_Permission__c p = new NewEd__Contact_Permission__c(
			NewEd__Token__c = 'ABC123',
			NewEd__Last_Import__c = DateTime.now()
		);
		insert p;

		NewEd__Contact_Info__c ci = new NewEd__Contact_Info__c(
			NewEd__First_Name__c = 'TEST',
			NewEd__Last_Name__c = 'TEST',
			NewEd__Email__c = 'TEST@TEST.COM',
			NewEd__External_Id__c = 'ABC123',
			NewEd__Contact_Permission__c = p.Id
		);
		insert ci;

		ci = [select Id, Student__c from NewEd__Contact_Info__c limit 1];
		system.assertNotEquals(null, ci.Student__c);

	}

	@isTest static void testDupeMergeExistingContact() {
		
		Contact c = new Contact(
			FirstName = 'TEST',
			LastName = 'TEST',
			Email = 'TEST@TEST.COM'
		);
		insert c;

		NewEd__Contact_Permission__c p = new NewEd__Contact_Permission__c(
			NewEd__Token__c = 'ABC123',
			NewEd__Last_Import__c = DateTime.now()
		);
		insert p;

		NewEd__Contact_Info__c ci = new NewEd__Contact_Info__c(
			NewEd__First_Name__c = 'TEST',
			NewEd__Last_Name__c = 'TEST',
			NewEd__Email__c = 'TEST@TEST.COM',
			NewEd__External_Id__c = 'ABC123',
			NewEd__Contact_Permission__c = p.Id
		);
		insert ci;

		ci = [select Id, Student__c from NewEd__Contact_Info__c limit 1];
		system.assertEquals(c.Id, ci.Student__c);

	}
	
}