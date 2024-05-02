global class MRK_MultiPullMarketoSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Map<Id,List<Marketo_Log__c>> markMap = new Map<Id,List<Marketo_Log__c>>();

        //GET LAST LOGS FOR RUN TIME
        markMap = getLogs();

        for(MRK_Payload_Parser__mdt mt : [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,Qualified_Object_Api__c,
                                            Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c, Url_Merge_Field__c, Is_Url_Merge__c
                                            FROM MRK_Payload_Parser__mdt WHERE Include_In_Main_Sync__c = true AND Is_Active__c = true AND Is_Url_Merge__c = true]){
            
            //CHECK LAST LOG FOR RUN TIME
            List<Marketo_Log__c> lastLogs = markMap.get(mt.Id);
            DateTime rightNow = System.now();                                    
            DateTime nextRun = rightNow.addMinutes(-Integer.valueOf(mt.Run_Every_min__c));     
            System.debug(lastLogs);
            System.debug(nextRun);                      
            if(lastLogs != null && lastLogs[0].End_Date__c <= nextRun){
                MRK_MultiPullMarketoBatch mbc = new MRK_MultiPullMarketoBatch(mt, rightNow, nextRun);
                Database.executebatch(mbc,50);
            }
            else if(lastLogs == null){
                 MRK_MultiPullMarketoBatch mbc = new MRK_MultiPullMarketoBatch(mt, rightNow, nextRun);
                Database.executebatch(mbc,50);                                     
            }
        }
    }

    global static Map<Id,List<Marketo_Log__c>> getLogs(){
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
}