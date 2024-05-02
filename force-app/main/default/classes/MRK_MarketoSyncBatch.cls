public with sharing class MRK_MarketoSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC){
        //PULL ALL ACTIVE AND INCLUDE IN SYNC CMDT
        String query = 'SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,'
        +'Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c '
        +'FROM MRK_Payload_Parser__mdt WHERE Include_In_Main_Sync__c = true AND Is_Active__c = true AND Is_Url_Merge__c = false';
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<MRK_Payload_Parser__mdt> scope){

        //RUN TIME VARS
        List<Marketo_Log__c> insertLogs = new List<Marketo_Log__c>();
        Map<Id,List<Marketo_Log__c>> markMap = new Map<Id,List<Marketo_Log__c>>();

        //GET LAST LOGS FOR RUN TIME
        markMap = getLogs();

        System.debug(scope);
        DateTime rightNow = System.now();

        //LOOP ALL CMDT
        for(MRK_Payload_Parser__mdt mt : scope){
            //CHECK LAST LOG FOR RUN TIME
            List<Marketo_Log__c> lastLogs = markMap.get(mt.Id);
            Integer runInterval = Integer.valueOf(mt.Run_Every_min__c);
            DateTime nextRun = rightNow.addMinutes(-runInterval);

            //NEW LOG
            Marketo_Log__c ml = MRK_LoggerHelper.createDefualtLog(nextRun, rightNow, mt);

            //GET START TOKEN
            String getPageToken = '/v1/activities/pagingtoken.json?sinceDatetime='+getGMTDate(nextRun.addMinutes(-10));

            String res = '';
			//DateTime runBuffer = nextRun.addMinutes(2);
            if(lastLogs != null && lastLogs[0].End_Date__c <= nextRun.addMinutes(1)){

                try{
                    //START API SESSION
                    MRK_SessionHandler sh = new MRK_SessionHandler();

                    //GET TIME TOKEN
                    MRK_SessionResponseModel returnTimeBody = sh.getRequest('', getPageToken, 'GET');
                    TimeRep timeObj = (TimeRep) System.JSON.deserialize(returnTimeBody.Message, TimeRep.class);

                    //SET BODY
                    String body = '';
                    if(mt.Sync_Type__c == 'GET'){
                        body = mt.json__c;
                    }
                    else if(mt.push_json__c != null){
                        body = processBody(mt);
                    }

                    //SET REQUEST
                    String request = mt.End_Point_Url__c + '&nextPageToken=' + timeObj.nextPageToken;
                    ml.Request__c = request;

                    //RECUR API CALLOUT FOR ALL PAGES
                    res = callOutHelper(sh, body, request, mt, '',ml);
                    System.debug(res);
                    ml.Response__c = res.length() > 20001 ? res.substring(0,20000) + ' \n .... Response Trimmed' : res;

                    //CALL OBJECT PROCESSOR
                    if(!mt.Utilize_Dynamic__c){
                        MRK_PayloadProcessorHelper.generateTasks('['+res+']', mt, ml);
                    }
                    else{
                        MRK_PayloadParser.processData(mt.DeveloperName, res, ml);
                    }

                    //NEW ADD LOG TO LIST
                    insertLogs.add(ml);

                }catch(Exception e){
                    //NEW ADD LOG TO LIST FAIL
                    ml.Status__c = 'Fail';
                    ml.Include_in_Retries__c = false;
                    ml.Error_Message__c = e.getMessage() + ' On Line: ' + e.getLineNumber();
                    ml.DML_Error__c = false;

                    MRK_LoggerHelper.insertLog(res, mt, ml);
                }
            }
            else if(lastLogs == null){

                try{
                    //START API SESSION
                    MRK_SessionHandler sh = new MRK_SessionHandler();

                    //GET TIME TOKEN
                    MRK_SessionResponseModel returnTimeBody = sh.getRequest('', getPageToken, 'GET');
                    TimeRep timeObj = (TimeRep) System.JSON.deserialize(returnTimeBody.Message, TimeRep.class);

                    //SET BODY
                    String body = '';
                    if(mt.Sync_Type__c == 'GET'){
                        body = mt.json__c;
                    }
                    else if(mt.push_json__c != null){
                        body = processBody(mt);
                    }

                    //SET REQUEST
                    String request = mt.End_Point_Url__c + '&nextPageToken=' + timeObj.nextPageToken;
                    ml.Request__c = request;

                    //RECUR API CALLOUT FOR ALL PAGES
                    res = callOutHelper(sh, body, request, mt, '',ml);
                    System.debug(res);
                    ml.Response__c = res.length() > 20001 ? res.substring(0,20000) + ' \n .... Response Trimmed' : res;

                    //CALL OBJECT PROCESSOR
                    if(!mt.Utilize_Dynamic__c){
                        MRK_PayloadProcessorHelper.generateTasks('['+res+']', mt, ml);
                    }
                    else{
                        MRK_PayloadParser.processData(mt.DeveloperName, res, ml);
                    }

                    //NEW ADD LOG TO LIST
                    insertLogs.add(ml);

                }catch(Exception e){
                    //NEW ADD LOG TO LIST FAIL
                    ml.Status__c = 'Fail';
                    ml.Include_in_Retries__c = false;
                    ml.Error_Message__c = e.getMessage() + ' On Line: ' + e.getLineNumber();
                    ml.DML_Error__c = false;

                    MRK_LoggerHelper.insertLog(res, mt, ml);
                }
            }
        }

        if(!insertLogs.isEmpty()){
            Database.insert(insertLogs,false);
        }
    }
  
    public void finish(Database.BatchableContext BC){
    }

    public static String callOutHelper(MRK_SessionHandler sh, String body, String request, MRK_Payload_Parser__mdt mt, String results, Marketo_Log__c ml){
        ResultFull rf = new ResultFull();

        String finalRes = '';
        if(results != ''){
            finalRes = results;
        }

        MRK_SessionResponseModel returnSyncBody = sh.getRequest(body, request, mt.Sync_Type__c);

        TimeRep res = (TimeRep) System.JSON.deserialize(returnSyncBody.Message, TimeRep.class);
        
        if(returnSyncBody.Message.contains('result')){
            String result = returnSyncBody.Message.substringBetween('"result":[', '],"success"');
            finalRes += result;
        }

        System.debug(res);
        if(res.success == true && res.moreResult == true){
            String requestNext = mt.End_Point_Url__c + '&nextPageToken=' + res.nextPageToken;

            //finalRes.addAll(callOutHelper(sh, body, requestNext, mt));
            System.enqueueJob(new MRK_PageTokenCalloutQueueable(sh, body, requestNext, mt, finalRes, ml));
            //finalRes += ',' + callOutHelper(sh, body, requestNext, mt, finalRes);
        }

        return finalRes;
    }

    public static Map<Id,List<Marketo_Log__c>> getLogs(){
        Map<Id,List<Marketo_Log__c>> markMap = new Map<Id,List<Marketo_Log__c>>();
        for(Marketo_Log__c ml : [SELECT Id, Name, Error_Message__c, Include_in_Retries__c, Marketo_CMDT_Id__c,End_Date__c,Start_Date__c,
                            Number_Of_Retries__c, Request__c, Response__c, Status__c FROM Marketo_Log__c WHERE Marketo_CMDT_Id__c != null ORDER BY CreatedDate DESC LIMIT 5000]){
            if(markMap.containsKey(ml.Marketo_CMDT_Id__c)){
                List<Marketo_Log__c> logs = markMap.get(ml.Marketo_CMDT_Id__c);
                logs.add(ml);
                markMap.put(ml.Marketo_CMDT_Id__c, logs);
            }
            else{
                markMap.put(ml.Marketo_CMDT_Id__c, new List<Marketo_Log__c>{ml});
            }
        }

        return markMap;
    }

    public static string processBody(MRK_Payload_Parser__mdt mr){
        String body = '';
        if(mr.push_json__c != '' && mr.push_json__c != null){
            List<sObject> ojbs = MRK_CalloutHelper.getRecord(mr);
            if(ojbs != null){
                body = MRK_CalloutHelper.replaceMergeFields(ojbs, mr);
            }
        }

        return body;
    }

    public static string getGMTDate(DateTime dt){
        String dtStr = '';
        dtStr+=dt.Year() < 10 ? '0' + dt.Year()  + '-' : dt.Year() + '-';
        dtStr+=dt.Month() < 10 ? '0' + dt.Month()  + '-' : dt.Month() + '-';
        dtStr+=dt.Day() < 10 ? '0' + dt.Day()  + 'T' : dt.Day() + 'T';
        dtStr+=dt.Hour() < 10 ? '0' + dt.Hour() + ':' : dt.Hour() + ':';
        dtStr+=dt.Minute() < 10 ? '0' + dt.Minute() + ':' : dt.Minute() + ':';
        dtStr+=dt.Second() < 10 ? '0' + dt.Second(): dt.Second()+'';

        dtStr = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        //return EncodingUtil.urlEncode(dtStr + '-05:00', 'UTF-8');
        return EncodingUtil.urlEncode(dtStr, 'UTF-8');
        //return dtStr + '-05:00';
    }

    public class TimeRep{
        public boolean success;
        public string nextPageToken;
        public string requestId;
        public boolean moreResult;
    }

    public class ResultFull{
        public TimeRep tr;
        public string resp;
        public string unformatedResp;
    }
}