global class MRK_CreateStaticListsSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        MRK_CreateStaticLists staticListBatch = new MRK_CreateStaticLists(); 
        Database.executebatch(staticListBatch, 10);
    }
}