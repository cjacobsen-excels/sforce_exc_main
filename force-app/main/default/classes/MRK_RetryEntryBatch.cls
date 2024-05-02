public with sharing class MRK_RetryEntryBatch implements Database.Batchable<sObject>{
  
    public Marketo_Api_Setting__mdt mainMarketoSetting;

    public MRK_RetryEntryBatch(){
        this.mainMarketoSetting = [SELECT Number_Of_Retries__c, Id, When_to_Clear_Logs__c, Who_Should_be_notified__c, Notifications_On__c, Marketo_Notification_Template__c 
                                    FROM Marketo_Api_Setting__mdt Limit 1];
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name, Error_Message__c, Include_in_Retries__c, Number_Of_Retries__c, Request__c,DML_Error__c,External_Id__c,Object_Api__c,Marketo_CMDT_Id__c,' +
        ' Response__c, Status__c FROM Marketo_Log__c WHERE Include_in_Retries__c = true AND Status__c = \'Fail\'' +
        ' AND Number_Of_Retries__c < ' + mainMarketoSetting.Number_Of_Retries__c;
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<Marketo_Log__c> scope){
        Map<Id,MRK_Payload_Parser__mdt> mdtMap = new Map<Id,MRK_Payload_Parser__mdt>();
        for(MRK_Payload_Parser__mdt mdtRec : [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
                                            Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c
                                            FROM MRK_Payload_Parser__mdt]){

            mdtMap.put(mdtRec.Id, mdtRec);
        }

        List<Id> logIds = new List<Id>();
        List<Marketo_Log__c> updateLogs = new List<Marketo_Log__c>();
        List<ContentDocument> deleteFiles = new List<ContentDocument>();
        List<ContentVersion> insertFiles = new List<ContentVersion>();
        for(Marketo_Log__c mkL : scope){
            logIds.add(mkL.Id);
        }

        Map<Id, ContentVersion> logMap = new Map<Id, ContentVersion>();
        for(ContentVersion cv : [SELECT Id, VersionData, FirstPublishLocationId, CreatedDate, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId IN: logIds ORDER BY CreatedDate ASC]){
            logMap.put(cv.FirstPublishLocationId, cv);
        }

        for(Marketo_Log__c mkL : scope){
            ContentVersion cv = logMap.get(mkL.Id);
            if(cv != null){
                Blob fileBody = cv.VersionData;
                String sessionResponce = fileBody.toString();
                
                if(mkL.DML_Error__c){
                    String listType = 'List<' + mkL.Object_Api__c + '>';
                    List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
                    List<sobject> res = (List<sobject>) System.JSON.deserialize(sessionResponce, List<sobject>.class);
                    castRecords.addAll(res);

                    SObjectType objectType = Schema.getGlobalDescribe().get(mkL.Object_Api__c);
                    Map<String,Schema.SObjectField> mfields = objectType.getDescribe().fields.getMap();
                    Database.UpsertResult[] srList = Database.upsert(castRecords,mfields.get(mkL.External_Id__c),false);
                    Integer i = 0;
                    List<sObject> failed = (List<SObject>)Type.forName(listType).newInstance();
                    for (Database.UpsertResult sr : srList) {
                        if (sr.isSuccess()) {
                            System.debug('Successfully inserted:: ' + sr.getId());
                        }
                        else {
                            failed.add(castRecords[i]);
                        }
                        i++;
                    }

                    if(!failed.isEmpty()){
                        mkL.Status__c = 'Fail';
                        mkl.Number_Of_Retries__c = mkl.Number_Of_Retries__c + 1;
                        mkL.Include_in_Retries__c = true;
                        updateLogs.add(mkL);

                        ContentVersion cvN = new ContentVersion();
                        cvN.Title = 'Log Body';
                        cvN.PathOnClient = 'marketoLog.txt';
                        cvN.VersionData = Blob.valueOf(JSON.serialize(failed));
                        cvN.IsMajorVersion = true;
                        cvN.FirstPublishLocationId = mkL.Id;

                        ContentDocument cd = new ContentDocument();
                        cd.Id = cv.ContentDocumentId; 
                        deleteFiles.add(cd);
                        insertFiles.add(cvN);
                    }
                    else{
                        mkL.Status__c = 'Success';
                        mkL.Include_in_Retries__c = false;
                        mkl.Number_Of_Retries__c = mkl.Number_Of_Retries__c + 1;
                        updateLogs.add(mkL);

                        ContentDocument cd = new ContentDocument();
                        cd.Id = cv.ContentDocumentId; 
                        deleteFiles.add(cd);
                    }
                }
                else{
                    MRK_Payload_Parser__mdt mt = mdtMap.get(mkL.Marketo_CMDT_Id__c);
                    if(mt != null){
                        if(!mt.Utilize_Dynamic__c){
                            mKl = MRK_PayloadProcessorHelper.generateTasks('['+sessionResponce+']', mt ,mkL);
                            updateLogs.add(mkL);
                        }
                        else{
                            mKl = MRK_PayloadParser.processData(mt.DeveloperName, sessionResponce, mkL);
                            updateLogs.add(mkL);
                        }
                    }else{
                        mkL.Status__c = 'Fail';
                        mkl.Number_Of_Retries__c = mkl.Number_Of_Retries__c + 1;
                        mkL.Include_in_Retries__c = true;
                        updateLogs.add(mkL);
                    }
                }
            }
        }

        if(!updateLogs.isEmpty()){
            Database.update(updateLogs,false);
        }

        if(!insertFiles.isEmpty()){
            Database.insert(insertFiles,false);
        }

        if(!deleteFiles.isEmpty()){
            Database.delete(deleteFiles,false);
        }
    }
  
    public void finish(Database.BatchableContext BC){
    }
}