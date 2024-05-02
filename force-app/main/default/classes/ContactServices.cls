public class ContactServices {

    public static void updateMarketingFields(Map<Id,Contact> new_map,Map<Id,Contact> old_map){
        Map<Id,Contact> changed_contacts = new Map<Id,Contact>(); 
        
        for(Contact c : new_map.values()){
            if(old_map != null){
                if(
                    (c.utm_campaign__c != old_map.get(c.Id).utm_campaign__c)
                    || (c.utm_source__c != old_map.get(c.Id).utm_source__c)
                    || (c.utm_medium__c != old_map.get(c.Id).utm_medium__c)
                  ){
                    changed_contacts.put(c.Id,c); 
                }
            }
            else{
                changed_contacts.put(c.Id,c);
            }
        }

        List<CampaignMember> members = new List<CampaignMember>(); 
        Set<Id> contact_ids = new Set<Id>(); 
        for(CampaignMember cm : [SELECT Id
                                        ,ContactId
                                        ,CampaignId
                                        ,utm_source__c
                                        ,utm_medium__c
                                        ,utm_campaign__c
                                FROM CampaignMember
                                WHERE ContactId IN :changed_contacts.keySet()
                                Order By LastModifiedDate desc
                                ]){
            //combination of ordering by created date in above SOQL and check set for contact id => update most recent Campaign Member
            if(!contact_ids.contains(cm.ContactId)){
                cm.utm_source__c = changed_contacts.get(cm.ContactId).utm_source__c; 
                cm.utm_medium__c = changed_contacts.get(cm.ContactId).utm_medium__c; 
                cm.utm_campaign__c = changed_contacts.get(cm.ContactId).utm_campaign__c; 
                members.add(cm);
                contact_ids.add(cm.ContactId);
            }
        }

        MarketingServices.SyncCampaignMembers(members);
        
    }
}