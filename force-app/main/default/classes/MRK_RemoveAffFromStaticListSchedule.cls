global class MRK_RemoveAffFromStaticListSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        MRK_RemoveAffiliationFromStaticListBatch mb = new MRK_RemoveAffiliationFromStaticListBatch();
		Database.executeBatch(mb,10);
    }
}