public with sharing class MRK_CalloutHelper {

    public static string replaceMergeFields(sObject sob, MRK_Payload_Parser__mdt mdt){
        List<fieldMapModel> fieldMap = (List<fieldMapModel>) System.JSON.deserialize(mdt.Sync_Field_Map__c, List<fieldMapModel>.class);
        String requestBody = '';

        //REP MERGE VALUES
        if(sob != null){
            String repBody = mdt.json__c;
            for(fieldMapModel fm : fieldMap){
                repBody = repBody.replace(fm.key, '"'+String.valueOf(sob.get(fm.value) == null ? '': sob.get(fm.value))+'"');
            }

            if(requestBody == ''){
                requestBody = repBody;
            }
            else{
                requestBody = requestBody + ',' + repBody;
            }
        }

        return requestBody;
    }

    public static string replaceMergeFields(List<sObject> sobs, MRK_Payload_Parser__mdt mdt){
        List<fieldMapModel> fieldMap = (List<fieldMapModel>) System.JSON.deserialize(mdt.Sync_Field_Map__c, List<fieldMapModel>.class);
        String requestBody = '';

        System.debug(mdt.push_json__c);

        //REP MERGE VALUES
        if(sobs != null){
            for(sObject sob : sobs){
                String repBody = mdt.push_json__c;
                for(fieldMapModel fm : fieldMap){
                    repBody = repBody.replace(fm.key, '"'+String.valueOf(sob.get(fm.value) == null ? '': sob.get(fm.value))+'"');
                }

                if(requestBody == ''){
                    requestBody = repBody;
                }
                else{
                    requestBody = requestBody + ',' + repBody;
                }
            }
        }

        return requestBody;
    }

    public static List<sObject> getRecord(MRK_Payload_Parser__mdt mdt){
        List<String> fields = new List<String>();

        //GET FIELDS
        List<fieldMapModel> fieldMap = (List<fieldMapModel>) System.JSON.deserialize(mdt.Sync_Field_Map__c, List<fieldMapModel>.class);
        for(fieldMapModel fmm : fieldMap){
            fields.add(fmm.value);
        }

        String query = 'SELECT Id, ' + string.join (fields, ',') + ' FROM ' + mdt.Sync_Object__c + ' WHERE Id != null';

        if(mdt.Qualified_Objects__c != null && mdt.Qualified_Objects__c != ''){
            query += ' AND ' + mdt.Qualified_Objects__c;
        }

        System.debug(query);

        List<sObject> objLst = Database.query(query);

        return objLst;
    }

    public class objectModel{
        public sObject obj;
        public Map<String,String> fieldToValueMap;
        public String requestBody;
    }

    public class fieldMapModel{
        public string key;
        public string value;
    }
}