public class MRK_CreateStaticLists implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public MRK_Payload_Parser__mdt mrkPublic;
    public Database.QueryLocator start(Database.BatchableContext BC){
        this.mrkPublic = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,
                    DeveloperName,Utilize_Dynamic__c, Sync_Fields__c, Sync_Object__c, Sync_Type__c, 
                    Sync_Field_Map__c,Run_Every_min__c FROM MRK_Payload_Parser__mdt WHERE Sync_Object__c = 'StaticList'];

        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        String query = 'SELECT Id, Name, Marketo_Static_List_Id__c FROM Account WHERE RecordTypeId =: devRecordTypeId AND Marketo_Static_List_Id__c = null AND POP_Code__c != \'\'';
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<Account> scope){
        createStaticList(scope, mrkPublic);
    }
  
    public void finish(Database.BatchableContext BC){
    }

    public static void createStaticList(List<Account> accs, MRK_Payload_Parser__mdt mrk){
        List<Account> accounts = new List<Account>();
        System.debug(accs.size());
        if(mrk != null){
            for(Account acc : accs){
                Folder folder = new Folder();
                folder.id_z = Integer.valueOf(mrk.push_json__c);
                folder.type_z = 'Folder';

                String folderStr = JSON.serialize(folder).replace('_z', '');

                String body = 'folder=' + folderStr +'&name=' + EncodingUtil.urlEncode(acc.Name, 'UTF-8');
                MRK_SessionHandler sh = new MRK_SessionHandler();
                MRK_SessionResponseModel returnTimeBody = sh.getRequest(body, mrk.End_Point_Url__c, 'POST');
                String res = returnTimeBody.Message;

                res = res.replace('id', 'id_z');
                StaticList formRep = (StaticList) System.JSON.deserialize(res, StaticList.class);
                if(formRep.success){
                    if(formRep.result.size()>0){
                        Account a = new Account();
                        a.Id = acc.Id;
                        a.Marketo_Static_List_Id__c = formRep.result[0].id_z;
                        accounts.add(a);
                    }
                }
            }
        }

        if(!accounts.isEmpty()){
            Database.update(accounts,false);
        }
    }

    public class StaticList{
        public boolean success;
        public List<Results> result;
    }

    public class Results{
        public string id_z;
        public string name;
    }

    public class Folder{
        public Integer id_z;
        public string type_z;
    }
}