/**
 * Created by MylesVerigin on 2021-11-04.
 */

global without sharing class ContactAffiliation_TDTM extends hed.TDTM_Runnable {
    global override hed.TDTM_Runnable.DmlWrapper run(
            List<SObject> newList, List<SObject> oldList,
            hed.TDTM_Runnable.Action triggerAction,
            Schema.DescribeSObjectResult objResult) {
        hed.TDTM_Runnable.DmlWrapper dmlWrapper = new hed.TDTM_Runnable.DmlWrapper();

        if (triggerAction == hed.TDTM_Runnable.Action.BeforeUpdate){
            List<Contact> oldListContact = (List<Contact>) oldList;
            List<Contact> newListContact = (List<Contact>) newList;
            Map<Id,Contact> oldMap = new Map<Id,Contact>(oldListContact);
            Map<Id,Contact> newMap = new Map<Id,Contact>(newListContact);
            Map<Id,Id> contactIdsToAccountId = new Map<Id,Id>();

            for (Id conId : oldMap.keySet()){
                // only changed CAP accounts
                if (oldMap.get(conId).Acad_Corp_Part_Ref__c != newMap.get(conId).Acad_Corp_Part_Ref__c
                        && newMap.get(conId).Acad_Corp_Part_Ref__c != null && newMap.get(conId).Changed_in_Community__c == true ){
                    // collect new account Ids to screen already created affiliations later on
                    contactIdsToAccountId.put(conId,newMap.get(conId).Acad_Corp_Part_Ref__c);
                    newMap.get(conId).Changed_in_Community__c = false;
                }
            }

            Id communityUserProfileId = [
                    SELECT Id
                    FROM Profile
                    WHERE Name = :traa_Constants.COMMUNITY_PROFILE
            ].Id;

            Set<Id> communityUserIds = new Set<Id>();
            // collect what contacts are community user profiles ( because complete won't run on them )
            for (User u : [
                    SELECT Id,ContactId,ProfileId
                    FROM User
                    WHERE ContactId IN :contactIdsToAccountId.keySet()
            ]){
                if (u.ProfileId == communityUserProfileId){
                    communityUserIds.add(u.ContactId);
                }
            }
            // screen out created affiliations for the existing contact for each account;
            for (hed__Affiliation__c affiliation : [
                    SELECT Id, hed__Account__c,hed__Contact__c
                    FROM hed__Affiliation__c
                    WHERE hed__Contact__c IN :contactIdsToAccountId.keySet()
                    AND hed__Account__c != null
            ]){
                Id accountAffiliationBeingCheck = contactIdsToAccountId.get(affiliation.hed__Contact__c);
                if (accountAffiliationBeingCheck == affiliation.hed__Account__c){
                    // this contact already has affiliation to this account do not create another
                    if (communityUserIds.contains(affiliation.hed__Contact__c)){
                        communityUserIds.remove(affiliation.hed__Contact__c);
                    }
                }
            }

            Id partnerId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get(traa_Constants.AFFILIATION_RECORD_NAME).getRecordTypeId();
            List<hed__Affiliation__c> newAffiliations = new List<hed__Affiliation__c>();
            for (Id contactId : communityUserIds){
                Contact currentContact = newMap.get(contactId);
                newAffiliations.add( new hed__Affiliation__c(
                        External_Partner_ID__c = currentContact.Learning_Zone_ID__c,
                        Partner_Store_ID__c = currentContact.Partner_Store_ID__c,
                        Est_Graduation_Date__c = currentContact.Est_Graduation_Date__c,
                        Partner_Affiliate__c = currentContact.Partner_Affiliate__c,
                        hed__Account__c = currentContact.Acad_Corp_Part_Ref__c,
                        hed__Contact__c = currentContact.Id,
                        OwnerId = currentContact.OwnerId,
                        hed__Primary__c = true,
                        RecordTypeId = partnerId
                ));
            }
            insert newAffiliations;
        }
        return dmlWrapper;
    }
}