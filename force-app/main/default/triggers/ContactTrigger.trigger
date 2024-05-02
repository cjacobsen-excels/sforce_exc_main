trigger ContactTrigger on Contact (after insert,after update) {
	ContactServices.updateMarketingFields(trigger.newMap,trigger.oldMap);
}