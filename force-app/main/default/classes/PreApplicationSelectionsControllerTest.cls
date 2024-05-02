/**
 * Created by mnahar on 30/06/21.
 */

@IsTest
private class PreApplicationSelectionsControllerTest {
    @IsTest
    static void getTermsTest() {
        Test.startTest();
        List<String> terms = PreApplicationSelectionsController.getApplicationTerms();
        Test.stopTest();
        System.assert(terms != null);
    }

    @IsTest
    static void getAreasTest() {
        Test.startTest();
        List<String> areas = PreApplicationSelectionsController.getAreaOfInterest();
        Test.stopTest();
        System.assert(areas != null);
    }

    @IsTest
    static void getLevelsTest() {
        Test.startTest();
        List<String> levels = PreApplicationSelectionsController.getLevelOfInterest();
        Test.stopTest();
        System.assert(levels != null);
    }

    @IsTest
    static void getAccountsTest() {
        //Create Academic Account Record
        Account parentAccount2 = (Account) tf_TestFactory.createSObject(tf_AccountWrapper.class, false);
        parentAccount2.Area__c = 'Nursing';
        parentAccount2.Level__c = 'Bachelors';
        parentAccount2.traa_Open_to_Application_Submissions__c = 'Yes';
        parentAccount2.Formatted_Name__c = 'BA in Nursing';
        //System.debug(parentAccount);
        insert parentAccount2;
		 //Create Term
		hed__Term__c termVar = new hed__Term__c();
		termVar.Name = 'SUMMER II - 8 WEEK-2021';
        termVar.hed__Account__c = parentAccount2.Id;
		insert termVar;
        Account parentAccount = (Account) tf_TestFactory.createSObject(tf_AccountWrapper.class, false);
		parentAccount.Starting_Term__c = termVar.Id;
		//parentAccount.Starting_Term__r.Name = 'SUMMER II - 8 WEEK-2021'Old;
        parentAccount.Area__c = 'Nursing';
        parentAccount.Level__c = 'Bachelors';
        parentAccount.traa_Open_to_Application_Submissions__c = 'Yes';
        parentAccount.Formatted_Name__c = 'BA in Nursing Clone';
        insert parentAccount;

        Test.startTest();
        Map<String, String> accounts = PreApplicationSelectionsController.getAcademicPrograms('SUMMER II - 8 WEEK-2021', 'Bachelors', 'Nursing');
        Test.stopTest();
        System.assert(accounts != null);
    }
}