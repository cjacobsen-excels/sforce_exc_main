global class ExcelsiorSelfRegisterController {
    
    private static String recaptchaSecretKey = Label.Google_Recaptcha_Secret_Key;
    
    public ExcelsiorSelfRegisterController() {

    }

    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
        Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    
    @AuraEnabled
    public static SelfRegistrationWrapper selfRegistrationProcess(String firstname ,String lastname, String email,String extraFields, String startUrl, String regConfirmUrl,String recaptchaResponse) {
        
        SelfRegistrationWrapper selfRegisterWrap = new SelfRegistrationWrapper();
        PerformOperationWithoutSharing performOperation = new PerformOperationWithoutSharing();
        selfRegisterWrap.errorMessage = Label.Invalid_Verification_Request;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Google_Site/recaptcha/api/siteverify');
        request.setMethod('POST');
        request.setBody('secret=' + recaptchaSecretKey + '&response=' + recaptchaResponse);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            Contact portalContact;
            String existingConId = '';
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (result.containsKey('success') && result.get('success') == true) {
                if (!result.containsKey('score')) {
                    List<User> existingUserList = (List<User>) performOperation.fetchExistingRecord(email,true);
                    if(!existingUserList.isEmpty()) {
                        selfRegisterWrap.errorMessage = Label.User_Already_Exist;
                        return selfRegisterWrap;
                    }
                    List<Contact> existingConList = (List<Contact>)performOperation.fetchExistingRecord(email,false);
                    if(existingConList.isEmpty()) {
                        portalContact = new Contact(FirstName = firstname, LastName = lastname, Email = email);
                        if(String.isNotBlank(extraFields)) {
                            List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);        
                            for (Object thisFieldObject : extraFieldsList) {
                                Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                                String fieldPath = (String) thisField.get('fieldPath');
                                if(fieldPath == 'Academic_Area_of_Interest__c') {
                                    fieldPath = 'Area_of_Interest__c';
                                }
                                Schema.SObjectField sof = Schema.SObjectType.Contact.fields.getMap().get(fieldPath);
                                if(sof != null && thisField.get('value') != null) {
                                    portalContact.put(sof, thisField.get('value'));    
                                }
                            }
                        }
                        try {
                            insert portalContact;
                            
                        }
                        catch(Exception ex) {
                            throw new AuraHandledException('Error in self registration due to:'+ex.getMessage());
                            
                        }
    
                    }
                    else {
                        portalContact = existingConList.get(0);
                        existingConId = portalContact.Id;
                    }
                    
                    List<Contact> portalConList = performOperation.fetchContactRecord(portalContact.Id);
                    List<Account> acctList = new List<Account>();
                    // Added this condition because  during contact creation for site guest user administrative account
                    // is not getting linked to the newly created contact
                    if(String.isBlank(portalConList.get(0).AccountId)) {
                        acctList = performOperation.fetchAccountId(portalContact.Id);
                    }
                    else {
                        acctList.add(new Account(Id = portalConList.get(0).AccountId));
                    }
                    String message = selfRegister(portalConList.get(0).FirstName,portalConList.get(0).LastName,
                                                  portalConList.get(0).Email,null,null,acctList.get(0).Id,regConfirmUrl,
                                                  extraFields,startUrl,existingConId,false);
                    if(String.isBlank(message)) {
                        selfRegisterWrap.successMessage = Label.Registered_User_Success;
                        // Added it because duplicate contact records were getting created so deleted the one which is without 
                        // AccountId and User linked to it
                        if(String.isBlank(existingConId)) {
                            performOperation.deleteDuplicateConWithoutAccountId(portalConList,acctList.get(0).Id);    
                        }
                    }
                    else {
                        selfRegisterWrap.errorMessage = message;
                    }
                }
            }
            else {
                selfRegisterWrap.errorMessage = Label.Invalid_Verification;
            }
        }
        return selfRegisterWrap;
        
    }
    @Testvisible
    private static String selfRegister(String firstname ,String lastname, String email, String password, String confirmPassword, 
                                       String accountId, String regConfirmUrl, String extraFields,String startUrl, 
                                       String existingConId, Boolean includePassword) {
        Savepoint sp = null;
        try {
            sp = Database.setSavepoint();
            
            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }
            
            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }
            
            User u = new User();
            u.Username = email;
            u.put('Email',email);
            
            u.FirstName = firstname;
            u.LastName = lastname;
            
            String networkId = Network.getNetworkId();

            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }
            
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);
                     
            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);        
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    if(sof != null && thisField.get('value') != null) {
                        u.put(sof, thisField.get('value'));
                    }
                    
                }
            }
                        
            if (includePassword) {    
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
             validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }
            
            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            String userId;
            Network_Name__mdt networkName = [SELECT MasterLabel FROM Network_Name__mdt LIMIT 1];
            if(String.isBlank(existingConId)) {
                userId = Site.createPortalUser(u, accountId, password);
            }
            else {
                PerformOperationWithoutSharing performOperation = new PerformOperationWithoutSharing();
                userId  = performOperation.insertPortalUser(existingConId, firstname, lastname, u);
            }
            if (networkName != null && userId != null) {
                assignPermissionSetToUser(userId, 'R_A_Community_User'); 
            }
            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';           
            }
            if (userId != null) { 
                if (password != null && password.length() > 1) {
                    ApexPages.PageReference lgn = Site.login(email, password, startUrl);
                    if(!Test.isRunningTest()) {
                     aura.redirect(lgn);
                    }
                }
                else {
                    ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                    if(!Test.isRunningTest()) {
                    aura.redirect(confirmRef);
                   }

                }
            }
            return null;
        }
        catch (Exception ex) {
            Database.rollback(sp);
            return ex.getMessage();            
        }
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        if(!Test.isRunningTest()) {
        if (fieldSet != null) {
            for (Schema.FieldSetMember f : fieldSet.getFields()) {
                Map<String, Object> fieldDetail = new Map<String, Object>();
                fieldDetail.put('dbRequired', f.getDBRequired());
                fieldDetail.put('fieldPath', f.getFieldPath());
                if(f.getLabel().equals('Phone')) {
                    fieldDetail.put('label', 'Cell Phone');
                }
                else {
                    fieldDetail.put('label', f.getLabel());    
                }
                fieldDetail.put('required', f.getRequired());
                fieldDetail.put('type', f.getType());
                fieldDetail.put('value', '');   // client will populate
                extraFields.add(fieldDetail);
            }}}
        return extraFields;
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);   
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    }
    
    private without sharing class PerformOperationWithoutSharing {
        
        private List<Account> fetchAccountId(Id contactId) {
            return [SELECT Id FROM Account WHERE hed__Primary_Contact__c =: contactId];
        }
        
        private List<Contact> fetchContactRecord(Id contactId) {
            return [SELECT Id,FirstName,LastName,Email,Area_Of_Interest__c, Level_Of_Interest__c,AccountId 
                    FROM Contact WHERE Id =: contactId];
        }
        
        private List<Sobject> fetchExistingRecord(String email, Boolean isUser) {
           //Incident no - IN00091456 Start
            Id devRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
            String objectName = 'Contact';
            List<String> fieldList = new List<String> {'Id','RecordTypeId'};
            if(isUser) {
                objectName = 'User';
                fieldList.clear();
                fieldList = new List<String> {'Id'};
            }
            String existingRecordQuery = 'SELECT '+ String.join(fieldList, ',') + ' FROM '+ objectName + ' WHERE ';
            if(isUser) {
                existingRecordQuery += 'Username = :email'; 
            }
            else {
                existingRecordQuery += 'Email = :email AND RecordTypeId !=: devRecordTypeId'; 
            }
            //Incident no - IN00091456 END
            return Database.query(existingRecordQuery);
            
        }
        
        private void deleteDuplicateConWithoutAccountId(List<Contact> portalConList, Id accId) {
            List<Contact> conWithAccountIdListUpdate = new List<Contact>();
            for(Contact conWithAccountId : [SELECT Id FROM Contact WHERE FirstName =:portalConList.get(0).FirstName 
                                            AND LastName =:portalConList.get(0).LastName AND Email =: portalConList.get(0).Email
                                            AND AccountId =: accId]) {
                conWithAccountIdListUpdate.add(new Contact(Id = conWithAccountId.Id, Area_Of_Interest__c = portalConList.get(0).Area_Of_Interest__c,
                                                          Level_Of_Interest__c = portalConList.get(0).Level_Of_Interest__c));                                
            }
            if(!conWithAccountIdListUpdate.isEmpty()) {
                update conWithAccountIdListUpdate;
            }
            
            delete [SELECT Id FROM Contact WHERE FirstName =:portalConList.get(0).FirstName 
                    AND LastName =:portalConList.get(0).LastName AND Email =: portalConList.get(0).Email
                    AND AccountId = null];
        }
        
        private String insertPortalUser(String contactId, String firstname, String lastname,User u) {
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name =: traa_ConstantsFrontEnd.TRAA_COMMUNITY_LOGIN_USER];
            u.ContactId = contactId;
// Added per issue caused for out of bounds error on shorter last names - INC IN00093448. We will add a static 1234 for names shorter than 4 Characters. 
            String name = firstname + lastname;
    		Integer length = name.length();
    		String alias = (length >= 4) ? name.substring(0, 4) : name.substring(0, length) + 1234;
// END of chnages for issue IN00093448
            u.Alias = alias.toLowerCase();
            u.ProfileId = portalProfile.Id;
            u.languagelocalekey = UserInfo.getLocale();
            u.localesidkey = UserInfo.getLocale();
            u.emailEncodingKey = 'UTF-8';
            u.timeZoneSidKey = UserInfo.getTimezone().getID();
            insert u;
            if(u != null) {
                return u.Id;
            }
            
            return null;
        }
    }
    
    public class SelfRegistrationWrapper {
        
        @AuraEnabled public String errorMessage {get;set;}
        @AuraEnabled public String successMessage {get;set;}
        
        public SelfRegistrationWrapper() {
            errorMessage = '';
            successMessage = '';
        }
    }
    
    @AuraEnabled
    public static List<String> getPicklistvalues(String objectName, String field_apiname,Boolean nullRequired){
        List<String> optionlist = new List<String>();       
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = field_map.get(field_apiname).getDescribe().getPickListValues();       
        if(nullRequired == true){
            optionlist.add('--None--');
        }       
        for (Schema.PicklistEntry pv : picklistValues) {
            optionlist.add(pv.getValue());
        }
        return optionlist;
    }
    
    @future
    public static void assignPermissionSetToUser(Id userId, String permSetName) {
        try{
             PermissionSet communityUserPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :traa_ConstantsFrontEnd.COMMUNITY_USER_PERMISSION_SET];
        PermissionSetAssignment permSetAssignment = new PermissionSetAssignment(PermissionSetId = communityUserPermissionSet.Id, AssigneeId = userId);
        insert permSetAssignment;
        }catch(Exception e){
            
        }
    }
    
}