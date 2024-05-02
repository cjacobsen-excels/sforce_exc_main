public class MRK_SyncMarketoCapFields implements Queueable, Database.AllowsCallouts {
    
    public List<hed__Affiliation__c> objects;

    public MRK_SyncMarketoCapFields(List<hed__Affiliation__c> objects) {
        this.objects = objects;
    }

    public void execute(QueueableContext context) {
        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,
        Utilize_Dynamic__c,Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName = 'Affiliation_Push_Sync' AND Is_Active__c = true];

        System.debug(mr);
        System.debug(objects);

        String body = '{"action":"updateOnly","lookupField":"id","input":[';

        if(mr != null){
            if(mr.push_json__c != '' && mr.push_json__c != null){
                System.debug(MRK_CalloutHelper.replaceMergeFields(objects, mr));
                body = body + MRK_CalloutHelper.replaceMergeFields(objects, mr);
            }

            body += ']}';

            try{
                System.debug(body);
                MRK_SessionHandler sh = new MRK_SessionHandler();
                MRK_SessionResponseModel returnTimeBody = sh.getRequest(body, mr.End_Point_Url__c, 'POST');
                System.debug(returnTimeBody.message);
            }catch(Exception e){
                System.debug(e.getMessage());
            }
        }
    }
}