/**
* @description     Test class for ExcelsiorSelfRegisterController
* @author          Meghna Vijay, Traction On Demand
* @date            2021-06-24
*/


@IsTest
public with sharing class ExcelsiorSelfRegisterControllerTest {
    
    static User setupUser {
        get {
            if (setupUser == null) {
                setupUser = [
                    SELECT Id, ProfileId
                    FROM User
                    WHERE Profile.Name = 'System Administrator'
                    AND IsActive = TRUE
                    AND Id != :UserInfo.getUserId()
                    LIMIT 1
                ];
            }
            return setupUser;
        }
        set;
    }
    
    /* Verifies that IsValidPassword method with various password combinations. */
    @IsTest
    static void testIsValidPassword() {
        System.assert(ExcelsiorSelfRegisterController.isValidPassword('password?@12334', 'password?@12334') == true);
        System.assert(ExcelsiorSelfRegisterController.isValidPassword('password?@12334', 'dummyPassword') == false);
        System.assert(ExcelsiorSelfRegisterController.isValidPassword('password?@12334', null) == false);
        System.assert(ExcelsiorSelfRegisterController.isValidPassword(null, 'fakePwd') == false);
    }
    
    @IsTest
    static void testSiteAsContainerEnabled() {
        System.assertNotEquals(null, ExcelsiorSelfRegisterController.siteAsContainerEnabled('https://portaleu1-developer-edition.eu11.force.com'));
    }
    
    @isTest
    static void testValidEmail() {
        Test.setMock(HttpCalloutMock.class, new ExcelsiorRegisterMockGenerator()); 
        String recaptchaResponse = '{"success": true}';
        Map < String, String > paramsMap = initializeParams();
		Test.startTest();
        	ExcelsiorSelfRegisterController.SelfRegistrationWrapper selfRegisterWrap = 
                ExcelsiorSelfRegisterController.selfRegistrationProcess(paramsMap.get('firstName'),paramsMap.get('lastName'), '','',
                                                                        paramsMap.get('startUrl'),paramsMap.get('regConfirmUrl'),
                                                                        recaptchaResponse);
			System.assertEquals(Label.Site.email_is_required, selfRegisterWrap.errorMessage, 'Email is required');
        	
        Test.stopTest();
        
    }
    
    @isTest
    static void testNewContactRegisterAfterVerification() {
        Test.setMock(HttpCalloutMock.class, new ExcelsiorRegisterMockGenerator()); 
        String recaptchaResponse = '{"success": true}';
        Map < String, String > paramsMap = initializeParams();
        Map < String, Object > fieldMap = new Map < String, Object > ();
        List < Map < String, Object >> fieldlist = new List < Map < String, Object >> ();
        fieldMap.put('Academic_Area_of_Interest__c', 'Test area of interest');
        fieldMap.put('Phone', '1234567890');
        fieldlist.add(fieldMap);
        String extraFields = JSON.serialize(fieldlist);
        Test.startTest();
        	ExcelsiorSelfRegisterController.SelfRegistrationWrapper selfRegisterWrap = 
                ExcelsiorSelfRegisterController.selfRegistrationProcess(paramsMap.get('firstName'),paramsMap.get('lastName'),
                                                                        paramsMap.get('email'),extraFields,paramsMap.get('startUrl'),
                                                                        paramsMap.get('regConfirmUrl'),recaptchaResponse);
        	List<Contact> newConCreatedList = [SELECT Id FROM Contact WHERE Email ='testUser@salesforce.com'];
        	System.assertEquals(true, newConCreatedList.size()>0, 'New portal contact is created');
        	System.assertEquals(Label.Registered_User_Success, selfRegisterWrap.successMessage, 'User registered in the portal');
        Test.stopTest();
    }
    
    @isTest
    static void testExistingContactRegisterAfterVerification() {
        Test.setMock(HttpCalloutMock.class, new ExcelsiorRegisterMockGenerator()); 
        Contact existingCon = (Contact)tf_TestFactory.createSObject(tf_ContactWrapper.class, false);
        existingCon.Email = 'testUser@salesforce.com';
        insert existingCon;
        String recaptchaResponse = '{"success": true}';
        Map < String, String > paramsMap = initializeParams();
        Test.startTest();
        	ExcelsiorSelfRegisterController.SelfRegistrationWrapper selfRegisterWrap = 
                ExcelsiorSelfRegisterController.selfRegistrationProcess(paramsMap.get('firstName'),paramsMap.get('lastName'),
                                                                        paramsMap.get('email'),null,paramsMap.get('startUrl'),
                                                                        paramsMap.get('regConfirmUrl'),recaptchaResponse);
        	System.assertEquals(Label.Registered_User_Success, selfRegisterWrap.successMessage,'User with existing contact registered in the portal');
        Test.stopTest();
    }
    @isTest
    static void testExistingSelfRegisteredUser() {
		Contact existingCon = (Contact)tf_TestFactory.createSObject(tf_ContactWrapper.class, false);
        existingCon.Email = 'testUser@salesforce.com';
        insert existingCon;
		User portalUser = new User(Username = 'portal@user.com.test',
                FirstName = 'Portal',
                Lastname = 'User',
                Email ='portal@user.com.test',
                Alias = 'puser',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                ProfileId = tf_TestFactory.getProfilebyName(traa_ConstantsFrontEnd.TRAA_COMMUNITY_LOGIN_USER).Id,
				ContactId = existingCon.Id);
		System.runAs(setupUser) {
			insert portalUser;
            ExcelsiorSelfRegisterController.validatePassword(portalUser,'testPassword', 'testPassword');
		}
        Test.setMock(HttpCalloutMock.class, new ExcelsiorRegisterMockGenerator());
        String recaptchaResponse = '{"success": true}';
        Map < String, String > paramsMap = initializeParams();
        paramsMap.put('firstName', 'Portal');
        paramsMap.put('lastName', 'User');
        paramsMap.put('email', 'portal@user.com.test');
        Test.startTest();
        	ExcelsiorSelfRegisterController.SelfRegistrationWrapper selfRegisterWrap = 
                ExcelsiorSelfRegisterController.selfRegistrationProcess(paramsMap.get('firstName'),paramsMap.get('lastName'),
                                                                        paramsMap.get('email'),null,paramsMap.get('startUrl'),
                                                                        paramsMap.get('regConfirmUrl'),recaptchaResponse);
        	System.assertEquals(Label.User_Already_Exist, selfRegisterWrap.errorMessage,'Existing User');
        Test.stopTest();
    }
    @IsTest
    static void testGetNullExtraFields() {
        System.assertEquals(new List < Map < String, Object >> (), ExcelsiorSelfRegisterController.getExtraFields(null));
    }
    
    @IsTest
    static void testGetNonEmptyExtraFields() {
        System.assertEquals(new List < Map < String, Object >> (), ExcelsiorSelfRegisterController.getExtraFields('field1'));
    }
    
        
    @IsTest
    static void ExcelsiorSelfRegisterControllerInstantiation() {
        ExcelsiorSelfRegisterController controller = new ExcelsiorSelfRegisterController();
        System.assertNotEquals(controller, null);
    }
    
    @IsTest
    static void testValidPassword() {
        Map < String, String > paramsMap = initializeParams();
        
             System.assertEquals(Label.site.passwords_dont_match, 
                            ExcelsiorSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 
                                                                         paramsMap.get('email'), paramsMap.get('password'), 
                                                                         paramsMap.get('confirmPasswordWrong'), null, 
                                                                         paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'),'', 
                                                                         true));
       
       
    }
    
    @IsTest
    static void testValidatePassword() {
        Map < String, String > paramsMap = initializeParams();
        
        System.assertEquals(null, 
                            ExcelsiorSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), 
                                                                         paramsMap.get('email'), paramsMap.get('password'), 
                                                                         paramsMap.get('confirmPasswordCorrect'), null, 
                                                                         paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'),'', 
                                                                         true));
      
    }
    
    @IsTest
    static void testPicklistValues() {
        System.assertEquals(true, ExcelsiorSelfRegisterController.getPicklistvalues('User', 'Academic_Area_Of_Interest__c', false).size()>0, 'Picklist values found');
    }
    
    @IsTest
    static void testSetExperienceId() {
        System.assertEquals(null, ExcelsiorSelfRegisterController.setExperienceId(null), 'Experience Id is null');
    }
    
    /* Helper method to initialize the parameters required for SelfRegistration. */
    private static Map < String, String > initializeParams() {
        Map < String, String > paramsMap = new Map < String, String > ();
        String firstName = 'test';
        String lastName = 'User';
        String email = 'testUser@salesforce.com';
        String password = 'testuser123';
        String confirmPasswordCorrect = 'testuser123';
        String confirmPasswordWrong = 'wrongpassword';
        String accountId = 'testuser123';
        String regConfirmUrl = 'http://registration-confirm.com';
        String startUrl = 'http://my.company.salesforce.com';
        paramsMap.put('firstName', firstName);
        paramsMap.put('lastName', lastName);
        paramsMap.put('email', email);
        paramsMap.put('password', password);
        paramsMap.put('confirmPasswordCorrect', confirmPasswordCorrect);
        paramsMap.put('confirmPasswordWrong', confirmPasswordWrong);
        paramsMap.put('accountId', accountId);
        paramsMap.put('regConfirmUrl', regConfirmUrl);
        paramsMap.put('startUrl', startUrl);
        return paramsMap;
    }
}