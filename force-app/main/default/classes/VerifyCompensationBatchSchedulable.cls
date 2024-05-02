global class VerifyCompensationBatchSchedulable implements Schedulable{
    global void execute(SchedulableContext sc) {
        VerifyCompensationBatch newBatch = new VerifyCompensationBatch();
        Database.executeBatch(newBatch, 20);
    }
}