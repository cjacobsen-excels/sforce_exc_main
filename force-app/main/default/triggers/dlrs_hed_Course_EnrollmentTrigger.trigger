/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_hed_Course_EnrollmentTrigger on hed__Course_Enrollment__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(hed__Course_Enrollment__c.SObjectType);
}