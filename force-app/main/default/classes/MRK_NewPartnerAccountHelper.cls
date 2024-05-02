public class MRK_NewPartnerAccountHelper implements Queueable, Database.AllowsCallouts{

    public List<Account> accounts;

    public MRK_NewPartnerAccountHelper(List<Account> accounts){
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        MRK_Payload_Parser__mdt mrkPublic = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,
                    DeveloperName,Utilize_Dynamic__c, Sync_Fields__c, Sync_Object__c, Sync_Type__c, 
                    Sync_Field_Map__c,Run_Every_min__c FROM MRK_Payload_Parser__mdt WHERE Sync_Object__c = 'StaticList'];
        
        if(mrkPublic != null){
            MRK_CreateStaticLists.createStaticList(accounts, mrkPublic);
        }
    }
}