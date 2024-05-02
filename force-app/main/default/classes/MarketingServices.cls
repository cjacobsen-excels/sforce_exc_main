public class MarketingServices {

    public static void SyncCampaignMembers(List<CampaignMember> members){
        List<Id> camp_ids = new List<Id>();
        Map<Id,List<Campaign>> child_campaigns = new Map<Id,List<Campaign>>(); 
        for(CampaignMember cm : members){
            camp_ids.add(cm.CampaignId);
            child_campaigns.put(cm.CampaignId,new List<Campaign>()); 
        }

        Id rt_id = [SELECT Id FROM RecordType WHERE SObjectType = 'Campaign' and Name = 'Source' LIMIT 1].Id;
        for(Campaign c : [SELECT Id
                                ,ParentId
                                ,Parent.Name
                                ,Name
                                ,Media_Channel__c
                                ,Medium__c
                                ,Content__c
                          FROM Campaign 
                          WHERE ParentId IN :camp_ids AND RecordTypeId = :rt_id]){
            child_campaigns.get(c.ParentId).add(c); 
        }

        for(CampaignMember cm : members){
            for(Campaign c : child_campaigns.get(cm.CampaignId)){                     
                if(cm.utm_source__c == c.Name){
                    cm.Source__c = c.Id; 
                    break;  
                }        
            }
        }

        update members; 
    }
}