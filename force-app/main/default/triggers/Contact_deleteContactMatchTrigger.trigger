trigger Contact_deleteContactMatchTrigger on Contact (before delete) {
	Set <Id> cIds = new Set<Id>();
    for (contact c : trigger.old)
        cIds.add(c.Id);
    delete [SELECT Id from Contact_Match__c WHERE Contact_Id__c IN :cIds];
}