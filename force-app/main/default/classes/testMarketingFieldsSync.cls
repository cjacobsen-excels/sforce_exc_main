@isTest
public class testMarketingFieldsSync {

    public static RecordType strategic_iniative = [SELECT Id FROM RecordType WHERE Name = 'Campaign' AND SObjectType = 'Campaign'];
    public static RecordType source_rt = [SELECT Id FROM RecordType WHERE Name = 'Source' AND SObjectType = 'Campaign'];

    static testMethod void testMarketingFieldsSyncContact(){
        List<Campaign> parent_campaigns = new List<Campaign>(); 


        //two top level campaigns
        Campaign c1 = new Campaign(Name = 'Campaign 1',RecordTypeId = strategic_iniative.Id);
        parent_campaigns.add(c1);  
        Campaign c2 = new Campaign(Name = 'Campaign 2',RecordTypeId = strategic_iniative.Id); 
        parent_campaigns.add(c2); 

        insert parent_campaigns; 

        List<Campaign> child_campaigns = new List<Campaign>(); 
        //two child campaigns for each parent
        Campaign cc1 = new Campaign(Name = 'Child Campaign 1',RecordTypeId = source_rt.Id,Media_Channel__c = 'Directory',Medium__c = 'Pandora',ParentId = c1.Id); 
        child_campaigns.add(cc1);

        system.debug(child_campaigns); 
        insert child_campaigns; 

        test.startTest(); 

        Contact c = new Contact(); 
        c.FirstName = 'test'; 
        c.LastName = 'contact'; 
        c.Email = 'test@test.com';
        insert c; 

        CampaignMember cm = new CampaignMember(); 
        cm.ContactId = c.Id; 
        cm.CampaignId = c2.Id; 
        insert cm; 

        c.utm_campaign__c = c2.Name; 
        c.utm_source__c = 'Print'; 
        c.utm_medium__c = 'Pandora';
        update c;

        CampaignMember assertion_cm = [SELECT Source__c,utm_campaign__c,utm_medium__c,utm_source__c FROM CampaignMember WHERE Id = :cm.Id]; 
        system.debug('source is ' + assertion_cm);
        //system.assertEquals(assertion_cm.Source__c,cc4.Id); 

        c.utm_campaign__c = c2.Name; 
        c.utm_source__c = 'Directory'; 
        c.utm_medium__c = 'Facebook';
        update c; 

        assertion_cm = [SELECT Source__c,utm_campaign__c,utm_medium__c,utm_source__c FROM CampaignMember WHERE Id = :cm.Id]; 
        system.debug('source is ' + assertion_cm);
        //system.assertEquals(assertion_cm.Source__c,cc3.Id); 

        c.utm_campaign__c = c1.Name; 
        c.utm_source__c = 'Print'; 
        c.utm_medium__c = 'Google';
        update c;

        test.stopTest(); 
    }

    static testMethod void testMarketingFieldsSyncLead(){
        List<Campaign> parent_campaigns = new List<Campaign>(); 
        
        /*NOTE: Workflow field update formula sets Campaign Name to 

        Parent.Name & "_" & Media_Channel_Code__c & "_" & Medium_Code__c & "_" & TEXT( Start_FYQ__c )
        */

        //two top level campaigns
        Campaign c1 = new Campaign(Name = 'Campaign 1',RecordTypeId = strategic_iniative.Id);
        parent_campaigns.add(c1);  
        Campaign c2 = new Campaign(Name = 'Campaign 2',RecordTypeId = strategic_iniative.Id); 
        parent_campaigns.add(c2); 

        insert parent_campaigns; 

        List<Campaign> child_campaigns = new List<Campaign>(); 
        //two child campaigns for each parent
        Campaign cc1 = new Campaign(Name = 'Child Campaign 1',RecordTypeId = source_rt.Id,Media_Channel__c = 'Directory',Medium__c = 'Pandora',ParentId = c1.Id); 
        child_campaigns.add(cc1);

        system.debug(child_campaigns); 
        insert child_campaigns; 

        test.startTest(); 

        Lead l = new Lead(); 
        l.LastName = 'test';
        l.Status = 'Open';
        l.Email = 'testemailaddress@test.com';
        l.Company = 'test student';
        insert l; 

        CampaignMember cm = new CampaignMember(); 
        cm.LeadId = l.Id; 
        cm.CampaignId = c2.Id; 
        insert cm; 

        l.utm_campaign__c = c2.Name; 
        l.utm_source__c = 'Print'; 
        l.utm_medium__c = 'Pandora'; 
        update l;

        CampaignMember assertion_cm = [SELECT Source__c,utm_campaign__c,utm_medium__c,utm_source__c FROM CampaignMember WHERE Id = :cm.Id]; 
        system.debug('source is ' + assertion_cm);
        //system.assertEquals(assertion_cm.Source__c,cc4.Id); 

        l.utm_campaign__c = c2.Name; 
        l.utm_source__c = 'Directory'; 
        l.utm_medium__c = 'Facebook'; 
        update l; 

        assertion_cm = [SELECT Source__c,utm_campaign__c,utm_medium__c,utm_source__c FROM CampaignMember WHERE Id = :cm.Id]; 
        system.debug('source is ' + assertion_cm);
        //system.assertEquals(assertion_cm.Source__c,cc3.Id); 

        l.utm_campaign__c = c1.Name; 
        l.utm_source__c = 'Print'; 
        l.utm_medium__c = 'Google'; 
        update l;

        test.stopTest(); 
    }
}