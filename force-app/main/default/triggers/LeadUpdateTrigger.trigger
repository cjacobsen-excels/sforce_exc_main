trigger LeadUpdateTrigger on Lead (after update) {
    String convStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true ORDER BY CreatedDate DESC LIMIT 1].MasterLabel;
    Id integrationUserId = [SELECT Id FROM User WHERE Name = 'Integration User' LIMIT 1].Id;

    List<Lead> leadsToConvert = new List<Lead>();
    for (Lead myLead : Trigger.new) {
        if (!myLead.isConverted && myLead.Convert_Lead__c == 'Yes') {
            leadsToConvert.add(myLead);
        }
    }
        
    List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();

    // Create the list of lead conversions
    for (Lead myLead : leadsToConvert) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.setConvertedStatus(convStatus);
        if (myLead.Owner.Type <> 'User') {
            lc.setOwnerId(integrationUserId);
        } // If the owner is a queue, make it the integration user
        leadConverts.add(lc);
    }

    // Break lead conversions into chunks of 100 and convert them
    if (!leadConverts.isEmpty()) {
        for (Integer i = 0; i <= leadConverts.size() / 100; i++) {
            List<Database.LeadConvert> tempList = new List<Database.LeadConvert>();
            Integer startIndex = i * 100;
            Integer endIndex = ((startIndex + 100) < leadConverts.size()) ? startIndex + 100 : leadConverts.size();
            for (Integer j = startIndex; j < endIndex; j++) {
                tempList.add(leadConverts[j]);
            }
            Database.LeadConvertResult[] lcrList = Database.convertLead(tempList, false);
            for (Database.LeadConvertResult lcr : lcrList) {
                System.assert(lcr.isSuccess());
            }
        }
    }
}