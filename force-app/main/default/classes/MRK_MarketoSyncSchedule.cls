global class MRK_MarketoSyncSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        MRK_MarketoSyncBatch mainSync = new MRK_MarketoSyncBatch(); 
        Database.executebatch(mainSync, 1);
    }
}