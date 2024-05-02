@isTest
public class testMarketingServices {

	//get Campaign memebers to test

	static testMethod void testChildCampaigns() {

		Id rt_id = [SELECT Id FROM RecordType WHERE SObjectType = 'Campaign' and Name = 'Source' LIMIT 1].Id;
		Id rt1_id = [SELECT Id FROM RecordType WHERE SObjectType = 'Campaign' and Name = 'Campaign' LIMIT 1].Id;

		//Create some parent Campaigns for testing:
		List<Campaign> testCampaings = TestUtils.createCampaigns('test', 1, false);
		
		testCampaings[0].RecordTypeId = rt1_id;

		insert testCampaings;

		//Create some child Campaigns for testing:
		List<Campaign> testChildCampaings = TestUtils.createChildCampaigns(testCampaings[0].Id, 'test Child', 1, false);
		
		testChildCampaings[0].RecordTypeId = rt_id;

		String testers = testChildCampaings[0].Name;

		insert testChildCampaings;

		Campaign testCamp = [SELECT Name FROM Campaign WHERE ID =: testChildCampaings[0].Id];

		//Create some Campaign Members for testing
		
		List<CampaignMember> lstCampaignMember = TestUtils.createCampaignMembers(testCampaings[0], 1, false);		
		
		lstCampaignMember[0].utm_source__c = testCamp.Name;
		
		insert lstCampaignMember;
		
		test.startTest();
			MarketingServices.SyncCampaignMembers(lstCampaignMember);
		test.stopTest();

		System.assertEquals(lstCampaignMember[0].Source__c, testChildCampaings[0].Id);

	}
}