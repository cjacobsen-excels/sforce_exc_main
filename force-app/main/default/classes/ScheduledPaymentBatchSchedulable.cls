global class ScheduledPaymentBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        ScheduledPaymentBatch newBatch = new ScheduledPaymentBatch();
        Database.executeBatch(newBatch, 20);
    }
}