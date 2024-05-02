public class MRK_PageTokenCallout implements Database.Batchable<MRK_Payload_Parser__mdt>, Database.AllowsCallouts, Database.Stateful {
    public MRK_SessionHandler sh;
    public String body;
    public String request;
    public List<MRK_Payload_Parser__mdt> mt;
    public String results;
    public Marketo_Log__c ml;

    public String requestNext;
    public boolean runnext;

    public MRK_PageTokenCallout(MRK_SessionHandler sh, String body, String request, List<MRK_Payload_Parser__mdt> mt, String results, Marketo_Log__c ml){
        this.sh = sh;
        this.body = body;
        this.request = request;
        this.mt = mt;
        this.results = results;
        this.ml = ml;
    }

    public Iterable<MRK_Payload_Parser__mdt> start(Database.BatchableContext BC){
        return (Iterable<MRK_Payload_Parser__mdt>)mt;
    }
  
    public void execute(Database.BatchableContext BC, List<MRK_Payload_Parser__mdt> scope){
        String res = '';
        runnext = false;
        MRK_SessionResponseModel returnSyncBody = sh.getRequest(body, request, scope[0].Sync_Type__c);

        TimeRep resBack = (TimeRep) System.JSON.deserialize(returnSyncBody.Message, TimeRep.class);
        
        if(returnSyncBody.Message.contains('result')){
            res = returnSyncBody.Message.substringBetween('"result":[', '],"success"');
        }

        System.debug(res);
        ml.Response__c = res.length() > 20001 ? res.substring(0,20000) + ' \n .... Response Trimmed' : res;

        //CALL OBJECT PROCESSOR
        if(!scope[0].Utilize_Dynamic__c){
            MRK_PayloadProcessorHelper.generateTasks('['+res+']', scope[0], ml);
        }
        else{
            MRK_PayloadParser.processData(scope[0].DeveloperName, res, ml);
        }

        System.debug(resBack);
        if(resBack.success == true && resBack.moreResult == true){
            requestNext = scope[0].End_Point_Url__c + '&nextPageToken=' + resBack.nextPageToken;
            runnext = true;
            //System.enqueueJob(new MRK_PageTokenCallout(sh, body, requestNext, mt, '', ml));
        }

        ml.Id = null;
        Database.SaveResult sr = Database.insert(ml,false);
        if (sr.isSuccess()) {
            System.debug('Successfully inserted: ' + sr.getId());
        }
        else {           
            for(Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');                    
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Fields that affected this error: ' + err.getFields());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if(runnext){
            Database.executeBatch(new MRK_PageTokenCallout(sh,body,requestNext,mt,results,ml),1);
        }
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