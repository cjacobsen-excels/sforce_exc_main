@isTest
private class TestMoveCasesOnLeadConversion {

	static testMethod void TestMoveCasesOnLeadConversion() {
		List<Lead> new_leads = new List<Lead>(); 

		Lead l = new Lead(); 
		l.LastName = 'test';
		l.Status = 'Open';
		l.Email = 'testemailaddress@test.com';
		l.Company = 'test student';
		new_leads.add(l);

		Lead l2 = new Lead(); 
		l2.LastName = 'test2';
		l2.Status = 'Open';
		l2.Email = 'testemailaddress2@test.com';
		l2.Company = 'test student 2';
		new_leads.add(l2);

		Lead l3 = new Lead(); 
		l3.LastName = 'test3';
		l3.Status = 'Open';
		l3.Email = 'testemailaddress3@test.com';
		l3.Company = 'test student 3';
		new_leads.add(l3);

		insert new_leads; 

		l3.Convert_Lead__c = 'Yes';

		update l3;

		List<Case> insert_cases = new List<Case>(); 

		Case c = new Case(); 
		c.Status = 'New';
		c.Description = 'test description'; 
		c.Subject = 'Test Subject';
		c.Origin = 'Email';
		c.Prospect__c = l.Id; 
		insert_cases.add(c);

		Case c1 = new Case(); 
		c1.Status = 'New';
		c1.Description = 'test description'; 
		c1.Subject = 'Test Subject';
		c1.Origin = 'Email';
		c1.Prospect__c = l.Id; 
		insert_cases.add(c1);

		insert insert_cases;

		test.startTest(); 

		Database.LeadConvert lead_conv = new database.LeadConvert();
		lead_conv.setLeadId(l.id);
		lead_conv.setDoNotCreateOpportunity(true);
		lead_conv.setConvertedStatus('Converted');
		Database.LeadConvertResult conv_res = Database.convertLead(lead_conv);

		system.assert(conv_res.success);//assert the conversion was successful 
		system.assertEquals(2,[SELECT Id FROM Case WHERE ContactId = :conv_res.contactId].size());//assert that both cases are now associated with the new contact
		
		//test that the lead with no cases doesn't get any 
		Database.LeadConvert lead_conv2 = new database.LeadConvert();
		lead_conv2.setLeadId(l2.id);
		lead_conv2.setDoNotCreateOpportunity(true);
		lead_conv2.setConvertedStatus('Converted');
		Database.LeadConvertResult conv_res2 = Database.convertLead(lead_conv2);

		system.assert(conv_res2.success);//assert the conversion was successful 
		system.assertEquals(0,[SELECT Id FROM Case WHERE ContactId = :conv_res2.contactId].size());//assert that the contact has no cases

		test.stopTest();

		//Checking the leads that do not get converted
		system.assertEquals('Yes', l3.Convert_Lead__c);
		system.assertEquals(false, l3.isConverted);
	}


}