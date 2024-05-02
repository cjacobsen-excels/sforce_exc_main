trigger NewEdContactTrigger on NewEd__Contact_Info__c (after insert, after update) {
	NewEdContactTriggerHandler.handle();
}