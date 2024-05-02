trigger CourseOfferingTrigger on hed__Course_Offering__c (before update, after update) {
    if (Trigger.isBefore) {
        if (CheckRecursive.runBefore) {
            CheckRecursive.runBefore = false;
            if (Trigger.isUpdate) {
                CourseOfferingTriggerHelper beforeHelper = new CourseOfferingTriggerHelper();
                beforeHelper.populateCompensation(Trigger.old, Trigger.newMap);
            }
        }
    }
    if (Trigger.isAfter) {
        if (CheckRecursive.runAfter) {
            CheckRecursive.runAfter = false;
            if (Trigger.isUpdate) {
                CourseOfferingTriggerHelper afterHelper = new CourseOfferingTriggerHelper();
                afterHelper.createPaymentsAfterUpdate(Trigger.old, Trigger.newMap);
                afterHelper.validateCompensationAmount(Trigger.old, Trigger.newMap);
            }
        }
    }
}