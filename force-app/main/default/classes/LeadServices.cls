public class LeadServices {

    public static void MoveCasesOnLeadConversion(List<Lead> t_new,List<Lead> old){
        Map<Id,Id> lead_ids = new Map<Id,Id>(); //list of lead ids to use to retrieve cases 
        List<Case> update_cases = new List<Case>(); 

        //move through trigger new and get leads that are converted and assemble ids to query cases
        for(Integer x = 0; x < t_new.size();x++){
            if(t_new[x].isConverted && !old[x].isConverted){
                lead_ids.put(t_new[x].Id,t_new[x].ConvertedContactId);
            }
        }

        for(Case c : [SELECT Id
                            ,ContactId
                            ,Prospect__c
                      FROM Case
                      WHERE Prospect__c IN :lead_ids.keySet()]){
            c.ContactId = lead_ids.get(c.Prospect__c);
            update_cases.add(c);
        }

        if(!update_cases.isEmpty()){
            update update_cases;
        }
    }

    public static void UpdateMarketingFields(Map<Id,Lead> new_map,Map<Id,Lead> old_map){
        Map<Id,Lead> changed_leads = new Map<Id,Lead>(); 
        Map<Id,List<Campaign>> child_campaigns = new Map<Id,List<Campaign>>(); 
        for(Lead l : new_map.values()){
            if(old_map != null){
                if(old_map != null){
                    if(
                        (l.utm_campaign__c != old_map.get(l.Id).utm_campaign__c)
                        || (l.utm_source__c != old_map.get(l.Id).utm_source__c)
                        || (l.utm_medium__c != old_map.get(l.Id).utm_medium__c)
                      ){
                            changed_leads.put(l.Id,l); 
                      }
                }

            }
            else{
                changed_leads.put(l.Id,l);
            }

        }

        List<Id> camp_ids = new List<Id>(); 
        Set<Id> lead_ids = new Set<Id>(); 
        List<CampaignMember> members = new List<CampaignMember>(); 
        for(CampaignMember cm : [SELECT Id
                                        ,LeadId
                                        ,CampaignId
                                        ,utm_source__c
                                        ,utm_medium__c
                                        ,utm_campaign__c
                                FROM CampaignMember
                                WHERE LeadId IN :changed_leads.keySet()
                                ORDER BY LastModifiedDate desc]){
            if(!lead_ids.contains(cm.LeadId)){
                cm.utm_source__c = changed_leads.get(cm.LeadId).utm_source__c; 
                cm.utm_medium__c = changed_leads.get(cm.LeadId).utm_medium__c; 
                cm.utm_campaign__c = changed_leads.get(cm.LeadId).utm_campaign__c; 
                members.add(cm);
                lead_ids.add(cm.LeadId);
            }
        }

        MarketingServices.SyncCampaignMembers(members);
    }
}