/**
 * Class containing tests for SiteRegisterController
 */
@IsTest public with sharing class SiteRegisterControllerTest {
    @IsTest(SeeAllData=true) static void testRegistration() {
        Account testact = TestUtils.createAccount('Test Account', TestUtils.getAccountRecordType('Partner'));
        insert testact;
        SiteRegisterController.PORTAL_ACCOUNT_ID = testact.Id;
        SiteRegisterController controller = new SiteRegisterController();
        controller.password = 'asdf1234';
        controller.confirmPassword = 'asdf1234';
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);  
    }
}