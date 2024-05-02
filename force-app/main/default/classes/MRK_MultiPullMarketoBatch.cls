public with sharing class MRK_MultiPullMarketoBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public MRK_Payload_Parser__mdt mt;
    public DateTime rightNow;
    public DateTime nextRun;

    public MRK_MultiPullMarketoBatch(MRK_Payload_Parser__mdt mt, DateTime rightNow, DateTime nextRun){
        this.mt = mt;
        this.rightNow = rightNow;
        this.nextRun = nextRun;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        //PULL ALL ACTIVE AND INCLUDE IN SYNC CMDT
        String query = mt.Qualified_Objects__c;
        System.debug(query);
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Marketo_Log__c> insertLogs = new List<Marketo_Log__c>();
        System.debug(scope.size());

        String urlMerge = '';
        SObjectType r = ((SObject)(Type.forName('Schema.'+mt.Qualified_Object_Api__c).newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        Schema.DisplayType typeValFlag = d.fields.getMap().get(mt.Url_Merge_Field__c).getDescribe().getType();

        for(sObject obj : scope){
            if(urlMerge == ''){
                if(String.valueOf(typeValFlag) == 'STRING'){
                    urlMerge += String.valueOf(obj.get(mt.Url_Merge_Field__c));
                }
                else if(String.valueOf(typeValFlag) == 'DECIMAL'){
                    urlMerge += Decimal.valueOf(String.valueOf(obj.get(mt.Url_Merge_Field__c)));
                }
                else if(String.valueOf(typeValFlag) == 'DOUBLE'){
                    urlMerge += Integer.valueOf(String.valueOf(obj.get(mt.Url_Merge_Field__c)));
                }
                else if(String.valueOf(typeValFlag) == 'INTEGER'){
                    urlMerge += String.valueOf(obj.get(mt.Url_Merge_Field__c));
                }
                else{
                    urlMerge += String.valueOf(obj.get(mt.Url_Merge_Field__c));
                }
            }
            else{
                if(String.valueOf(typeValFlag) == 'STRING'){
                    urlMerge += ',' + String.valueOf(obj.get(mt.Url_Merge_Field__c));
                }
                else if(String.valueOf(typeValFlag) == 'DECIMAL'){
                    urlMerge += ',' + Decimal.valueOf(String.valueOf(obj.get(mt.Url_Merge_Field__c)));
                }
                else if(String.valueOf(typeValFlag) == 'DOUBLE'){
                    urlMerge += ',' + Integer.valueOf(String.valueOf(obj.get(mt.Url_Merge_Field__c)));
                }
                else if(String.valueOf(typeValFlag) == 'INTEGER'){
                    urlMerge += ',' + String.valueOf(obj.get(mt.Url_Merge_Field__c));
                }
                else{
                    urlMerge += ',' + String.valueOf(obj.get(mt.Url_Merge_Field__c));
                }
            }
        }

        //NEW LOG
        Marketo_Log__c ml = MRK_LoggerHelper.createDefualtLog(nextRun, rightNow, mt);
        String res = '';

        try{
            //START API SESSION
            MRK_SessionHandler sh = new MRK_SessionHandler();

            //GET TIME TOKEN
            //MRK_SessionResponseModel returnTimeBody = sh.getRequest('', getPageToken, 'GET');
            //TimeRep timeObj = (TimeRep) System.JSON.deserialize(returnTimeBody.Message, TimeRep.class);

            //SET BODY
            String body = '';
            if(mt.Sync_Type__c == 'GET'){
                body = mt.json__c;
            }
            else if(mt.push_json__c != null){
                body = processBody(mt);
            }

            //SET REQUEST
            String urlRequest = mt.End_Point_Url__c;
            if(urlRequest.contains('{!v.')){
                String first = urlRequest.substringBefore('{!v.');
                String last = urlRequest.substringAfter('}');

                urlRequest = first + urlMerge + last;
            }
            String request = urlRequest;
            ml.Request__c = request;

            //RECUR API CALLOUT FOR ALL PAGES
            res = callOutHelper(sh, body, request, mt, '');
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

        if(!insertLogs.isEmpty()){
            Database.insert(insertLogs,false);
        }
    }
  
    public void finish(Database.BatchableContext BC){
    }

    public static String callOutHelper(MRK_SessionHandler sh, String body, String request, MRK_Payload_Parser__mdt mt, String results){
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

            finalRes += ',' + callOutHelper(sh, body, requestNext, mt, finalRes);
        }

        return finalRes;
    }

    public static Map<Id,List<Marketo_Log__c>> getLogs(){
        Map<Id,List<Marketo_Log__c>> markMap = new Map<Id,List<Marketo_Log__c>>();
        for(Marketo_Log__c ml : [SELECT Id, Name, Error_Message__c, Include_in_Retries__c, Marketo_CMDT_Id__c,End_Date__c,Start_Date__c,
                            Number_Of_Retries__c, Request__c, Response__c, Status__c FROM Marketo_Log__c WHERE Marketo_CMDT_Id__c != null ORDER BY CreatedDate LIMIT 5000]){
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

        return EncodingUtil.urlEncode(dtStr + '-05:00', 'UTF-8');
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