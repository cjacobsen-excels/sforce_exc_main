global class MRK_RetryEntrySchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        MRK_RetryEntryBatch b = new MRK_RetryEntryBatch(); 
        Database.executebatch(b, 10);
     }
}