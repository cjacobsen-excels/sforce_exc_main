public with sharing class MRK_LoggerHelper {
    
    public static Marketo_Log__c createLog(String errorMessage, Boolean includeInRetries, Integer numberOfRetries, String request, String response, String status){
        Marketo_Log__c ml = new Marketo_Log__c(Error_Message__c = errorMessage, Include_in_Retries__c = includeInRetries, Number_Of_Retries__c = numberOfRetries, 
        Request__c = request, Response__c = response, Status__c = status);
        insert ml;
        return ml;
    }

    public static Marketo_Log__c updateLog(Id mlId, String errorMessage, Boolean includeInRetries, Integer numberOfRetries, String request, String response, String status){
        Marketo_Log__c ml = new Marketo_Log__c(Id = mlId, Error_Message__c = errorMessage, Include_in_Retries__c = includeInRetries, Number_Of_Retries__c = numberOfRetries, 
        Request__c = request, Response__c = response, Status__c = status);
        Update ml;
        return ml;
    }

    public static Marketo_Log__c createDefualtLog(DateTime nextRun, DateTime rightNow, MRK_Payload_Parser__mdt mt){
        Marketo_Log__c ml = new Marketo_Log__c();
        ml.Start_Date__c = nextRun;
        ml.End_Date__c = rightNow;
        ml.Status__c = 'Success';
        ml.Number_Of_Retries__c = 0;
        ml.Include_in_Retries__c = false;
        ml.Marketo_CMDT_Id__c = mt.Id;

        return ml;
    }

    public static Marketo_Log__c getLog(Id LogId){
        return [SELECT Id, Name, Error_Message__c, Include_in_Retries__c, Number_Of_Retries__c, Request__c, Response__c, Status__c FROM Marketo_Log__c WHERE Id =: LogId];
    }

    public static void notify(Marketo_Log__c ml){
        Marketo_Api_Setting__mdt mrkCmdt = [SELECT Id, Marketo_Notification_Template__c, Notifications_On__c, 
                                            Number_Of_Retries__c, Start_Date__c, When_to_Clear_Logs__c, Who_Should_be_notified__c 
                                            FROM Marketo_Api_Setting__mdt WHERE DeveloperName = 'Main_Setting'];

        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName =: mrkCmdt.Marketo_Notification_Template__c];

        List<String> emails = new List<String>();
        if(mrkCmdt.Who_Should_be_notified__c != null){
            for(String steEmail : mrkCmdt.Who_Should_be_notified__c.split(',')){
                emails.add(steEmail.trim());
            }
        }

        if(!emails.isEmpty()){
            if(ml.Status__c == 'Fail' && (mrkCmdt.Notifications_On__c == 'Fail' || mrkCmdt.Notifications_On__c == 'Both')){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage message2 = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), ml.Id);
                message.setTargetObjectId(UserInfo.getUserId()); 
                message.setTreatTargetObjectAsRecipient(false);
                message.setSenderDisplayName('Marketo Admin Sync Fail'); 
                message.setUseSignature(false); 
                message.setBccSender(false); 
                message.setSaveAsActivity(false);
                message.setTemplateID(emailTemplate.Id); 
                message.setPlainTextBody(message2.getPlainTextBody());
                message.setSubject(message2.getSubject());
                message.setWhatId(ml.Id);
                message.toAddresses = emails;
                    
                allEmails.add(message);
            }
            else if(ml.Status__c == 'Success' && (mrkCmdt.Notifications_On__c == 'Success' || mrkCmdt.Notifications_On__c == 'Both' || Test.isRunningTest())){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage message2 = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), ml.Id);
                message.setTargetObjectId(UserInfo.getUserId()); 
                message.setTreatTargetObjectAsRecipient(false);
                message.setSenderDisplayName('Marketo Admin Sync Success'); 
                message.setUseSignature(false); 
                message.setBccSender(false); 
                message.setSaveAsActivity(false);
                message.setTemplateID(emailTemplate.Id); 
                message.setPlainTextBody(message2.getPlainTextBody());
                message.setSubject(message2.getSubject());
                message.setWhatId(ml.Id);
                message.toAddresses = emails;
                    
                allEmails.add(message);
            }
        }

        if(!Test.isRunningTest() && !allEmails.isEmpty()){
			Messaging.SendEmailResult[] results = Messaging.sendEmail(allEmails,false);
			for(Integer i = 0; i < results.size(); i++){ if(results[i].isSuccess()) System.debug('The email was sent successfully.'); else System.debug('The email failed to send: ' +  results[i].getErrors()[0].message);}
		}
    }

    public static void notify(List<Marketo_Log__c> mls){
        Marketo_Api_Setting__mdt mrkCmdt = [SELECT Id, Marketo_Notification_Template__c, Notifications_On__c, 
                                            Number_Of_Retries__c, Start_Date__c, When_to_Clear_Logs__c, Who_Should_be_notified__c 
                                            FROM Marketo_Api_Setting__mdt WHERE DeveloperName = 'Main_Setting'];

        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName =: mrkCmdt.Marketo_Notification_Template__c];

        List<String> emails = new List<String>();
        if(mrkCmdt.Who_Should_be_notified__c != null){
            for(String steEmail : mrkCmdt.Who_Should_be_notified__c.split(',')){
                emails.add(steEmail.trim());
            }
        }

        if(!emails.isEmpty()){
            for(Marketo_Log__c ml : mls){
                if(ml.Status__c == 'Fail' && (mrkCmdt.Notifications_On__c == 'Fail' || mrkCmdt.Notifications_On__c == 'Both')){
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage message2 = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), ml.Id);
                    message.setTargetObjectId(UserInfo.getUserId()); 
                    message.setTreatTargetObjectAsRecipient(false);
                    message.setSenderDisplayName('Marketo Admin Sync Fail'); 
                    message.setUseSignature(false); 
                    message.setBccSender(false); 
                    message.setSaveAsActivity(false);
                    message.setTemplateID(emailTemplate.Id); 
                    message.setPlainTextBody(message2.getPlainTextBody());
                    message.setSubject(message2.getSubject());
                    message.setWhatId(ml.Id);
                    message.toAddresses = emails;
                        
                    allEmails.add(message);
                }
                else if(ml.Status__c == 'Success' && (mrkCmdt.Notifications_On__c == 'Success' || mrkCmdt.Notifications_On__c == 'Both' || Test.isRunningTest())){
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage message2 = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), ml.Id);
                    message.setTargetObjectId(UserInfo.getUserId()); 
                    message.setTreatTargetObjectAsRecipient(false);
                    message.setSenderDisplayName('Marketo Admin Sync Success'); 
                    message.setUseSignature(false); 
                    message.setBccSender(false); 
                    message.setSaveAsActivity(false);
                    message.setTemplateID(emailTemplate.Id); 
                    message.setPlainTextBody(message2.getPlainTextBody());
                    message.setSubject(message2.getSubject());
                    message.setWhatId(ml.Id);
                    message.toAddresses = emails;
                        
                    allEmails.add(message);
                }
            }
        }

        if(!Test.isRunningTest() && !allEmails.isEmpty()){
			Messaging.SendEmailResult[] results = Messaging.sendEmail(allEmails,false);
			for(Integer i = 0; i < results.size(); i++){ if(results[i].isSuccess()) System.debug('The email was sent successfully.'); else System.debug('The email failed to send: ' +  results[i].getErrors()[0].message);}
        }
    
    }

    public static Marketo_Log__c insertLog(String body, MRK_Payload_Parser__mdt mt, Marketo_Log__c ml){
        if(body != ''){
            ml.Status__c = 'Fail';
            ml.Include_in_Retries__c = true;
        }
        try{
            insert ml;

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Log Body';
            cv.PathOnClient = 'marketoLog.txt';
            cv.VersionData = Blob.valueOf(body != '' && body != null ? body : 'No Log');
            cv.IsMajorVersion = true;
            cv.FirstPublishLocationId = ml.Id;
            Database.insert(cv,false);

        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());
        }

        return ml;
    }
}