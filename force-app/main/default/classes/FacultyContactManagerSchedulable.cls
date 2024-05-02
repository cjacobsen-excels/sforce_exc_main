global class FacultyContactManagerSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
		FacultyContactManagerBatchable fcmb = new FacultyContactManagerBatchable();
		Database.executeBatch(fcmb,200);
	}
}