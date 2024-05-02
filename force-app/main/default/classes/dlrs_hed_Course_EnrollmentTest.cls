/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_hed_Course_EnrollmentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_hed_Course_EnrollmentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new hed__Course_Enrollment__c());
    }
}