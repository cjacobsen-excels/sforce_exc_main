global class CalculatePaymentsBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        CalculatePaymentsBatch newBatch = new CalculatePaymentsBatch();
        Database.executeBatch(newBatch, 20);
    }
}