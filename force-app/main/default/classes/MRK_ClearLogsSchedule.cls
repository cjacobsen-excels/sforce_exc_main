global class MRK_ClearLogsSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        MRK_ClearLogsBatch b = new MRK_ClearLogsBatch(); 
        Database.executebatch(b, 10);
     }
}