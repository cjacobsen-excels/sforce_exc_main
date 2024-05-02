global class ScheduledPaymentBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        String query = 'SELECT Id '
        + 'FROM Payment__c '
        + 'WHERE Payment_Status__c = \'Scheduled\' AND Payment_Date__c < :today';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Payment__c> records) {
        List<Payment__c> recordsToUpdate = new List<Payment__c>(); 
        for (Payment__c payment : records) {
            payment.Payment_Status__c = 'Completed';
            recordsToUpdate.add(payment);
        }
        Database.update(recordsToUpdate);
    }
    
    global void finish(Database.BatchableContext bc) {

    }
}