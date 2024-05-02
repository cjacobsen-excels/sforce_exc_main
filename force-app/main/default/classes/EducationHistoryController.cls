/**
 * Created by mnahar on 23/06/21.
 */

public without sharing class EducationHistoryController {

    //Gets all Education History records for logged in user
    @AuraEnabled
    public static List<traa_Educational_History__c> getEducationHistoryRecords() {
        try {
            Id userId = UserInfo.getUserId();
            User commUser = [
                    SELECT Id, ContactId
                    FROM User
                    WHERE Id = :userId
            ];

            if(commUser != null){
                List<hed__Application__c> applications = [
                        SELECT Id
                        FROM hed__Application__c
                        WHERE hed__Applicant__c = :commUser.ContactId
                ];

                return [
                        SELECT Id, Name, traa_Institution_Name__c, traa_Application__r.Name, Transcript_Status__c
                        FROM traa_Educational_History__c
                        WHERE traa_Application__c IN :applications
                ];
            }
            return null;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

}