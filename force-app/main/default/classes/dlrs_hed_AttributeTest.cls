/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_hed_AttributeTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_hed_AttributeTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new hed__Attribute__c());
    }
}