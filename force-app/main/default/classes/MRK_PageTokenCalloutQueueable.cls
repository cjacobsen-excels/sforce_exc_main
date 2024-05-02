public class MRK_PageTokenCalloutQueueable implements Queueable, Database.AllowsCallouts{
    public MRK_SessionHandler sh;
    public String body;
    public String request;
    public List<MRK_Payload_Parser__mdt> mt;
    public String results;
    public Marketo_Log__c ml;

    public MRK_PageTokenCalloutQueueable(MRK_SessionHandler sh, String body, String request, MRK_Payload_Parser__mdt mt, String results, Marketo_Log__c ml){
        this.sh = sh;
        this.body = body;
        this.request = request;
        this.mt = new List<MRK_Payload_Parser__mdt> {mt};
        this.results = results;
        this.ml = ml;
    }

    public void execute(QueueableContext context){
        System.debug(request);
        Database.executeBatch(new MRK_PageTokenCallout(sh,body,request,mt,results,ml),1);
    }
}