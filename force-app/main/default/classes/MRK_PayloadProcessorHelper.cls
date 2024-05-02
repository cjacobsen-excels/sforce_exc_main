public class MRK_PayloadProcessorHelper {
    public static Boolean isFirstTime = true;
    
    public static Marketo_Log__c generateTasks(String payload, MRK_Payload_Parser__mdt mt, Marketo_Log__c ml){
        List<Marketo_Log__c> logs = new List<Marketo_Log__c>();
        List<hed__Affiliation__c> affiliations = new List<hed__Affiliation__c>();
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        if(payload != '' && mt.Sync_Object__c == 'Task'){
            //TASK DATA SETUP
            MRK_Payload_Parser__mdt mtActCode = getActivityTypes();
            Map<String,String> emTemps = getAllEmailTemps();
            List<MRK_TaskModel> taskMap = (List<MRK_TaskModel>) System.JSON.deserialize(payload, List<MRK_TaskModel>.class);
            Map<Integer,String> activityMapType = (Map<Integer,String>) System.JSON.deserialize(mtActCode.json__c, Map<Integer,String>.class);

            List<String> leadIds = new List<String>();
            for(MRK_TaskModel mrk : taskMap){
                leadIds.add(String.valueOf(mrk.leadId));
            }

            Map<String, String> mapOfExternalIdRefs = getExternalIdMap('Marketo_Id__c', 'Contact', leadIds);
            Map<String, String> mapOfExternalIdLeadRefs = getExternalIdMap('Marketo_Id__c', 'Lead', leadIds);

            Map<Id, Set<Id>> contoAff = new Map<Id, Set<Id>>();
            contoAff = currentAff(mapOfExternalIdRefs.values());

            List<Task> tasks = new List<Task>();
            //TASK DATA SETUP END

            //MAIN LOOP
            for(MRK_TaskModel mrk : taskMap){
                String leadId = mapOfExternalIdLeadRefs.get(String.valueOf(mrk.leadId));
                String conId = mapOfExternalIdRefs.get(String.valueOf(mrk.leadId));

                String otherVal = '';
                if(mrk.attributes != null){
                    for(MRK_TaskModel.Attribute at : mrk.attributes){
                        otherVal += at.name + ': ' + at.value + '\n';
                    }
                }

                if(mrk.fields != null){
                    for(MRK_TaskModel.Field f : mrk.fields){
                        otherVal += f.name + ': ' + f.newValue + ' from: ' + f.oldValue + '\n';
                    }
                }

                if(mrk.activityTypeId != 13 || (mrk.primaryAttributeValue == 'CAP/Academic Partner Referral' || mrk.primaryAttributeValue == '2nd CAP/Academic Partner Referral')){
                    Task t = new Task();
                    t.Marketo_Activity_Id__c = mrk.marketoGUID;
                    t.Subject = activityMapType.get(mrk.activityTypeId) + ': ' + mrk.primaryAttributeValue;

                    if(mrk.activityTypeId == 6 || mrk.activityTypeId == 7 || mrk.activityTypeId == 10 || mrk.activityTypeId == 11){
                        String trimmed = mrk.primaryAttributeValue.length() > 80 ? mrk.primaryAttributeValue.substring(0, 80) : mrk.primaryAttributeValue;
                        String etId  = emTemps.get(trimmed);
                        t.Description = 'PrimaryAttributeValueId: ' + String.valueOf(mrk.primaryAttributeValueId) + '\n Other: ' + otherVal + '\n CampaignId: ' + mrk.campaignId + '\nFrom: {{lead.Lead Owner First Name:default=Your Admissions}} {{lead.Lead Owner Last Name:default=Counselor}} {{lead.Lead Owner Email Address:default=EMAIL}}. Click ' + (etId != '' && etId != null ? URL.getSalesforceBaseUrl().toExternalForm() + '/' + etId : '[No Template Found]') + ' for email details';
                    }
                    else{
                        t.Description = 'PrimaryAttributeValueId: ' + String.valueOf(mrk.primaryAttributeValueId) + '\n Other: ' + otherVal + '\n CampaignId: ' + mrk.campaignId;
                    }

                    if(conId != null){
                        t.WhoId = conId;
                    }
                    else if(leadId != null){
                        t.WhoId = leadId;
                    }

                    t.ActivityDate = Date.valueOf(mrk.activityDate);
                    t.Completed_Date__c = Date.valueOf(mrk.activityDate);
                    t.Status = 'Completed';

                    if(mrk.primaryAttributeValue == 'CAP/Academic Partner Referral'){
                        //t.Created_By_Marketo_Integration__c = true;
                        t.CAP_Field_Update__c = 'CAP/Academic Partner Referral';
                        for(MRK_TaskModel.Attribute at : mrk.attributes){
                            if(at.name == 'Old Value'){
                                t.Marketo_Previous__c = at.value;
                            }
                            if(at.name == 'New Value'){
                                t.Marketo_Next__c = at.value;
                            }
                        }

                        if(t.whoId != null && String.valueOf(t.WhoId).startswith('003')){
                            Set<Id> accSet = contoAff.get(t.whoId);
                            if(accSet != null && !accSet.contains(t.Marketo_Next__c)){
                                hed__Affiliation__c tp = new hed__Affiliation__c();
                                tp.hed__Contact__c = t.whoId;
                                tp.hed__Account__c = t.Marketo_Next__c;
                                tp.hed__StartDate__c = System.today();
                                tp.hed__Status__c = 'Active';
                                tp.hed__Primary__c = false;
                                tp.Marketo_Created__c = true;
                                tp.RecordTypeId = devRecordTypeId;

                                affiliations.add(tp);
                            }
                            else if(accSet == null){
                                hed__Affiliation__c tp = new hed__Affiliation__c();
                                tp.hed__Contact__c = t.whoId;
                                tp.hed__Account__c = t.Marketo_Next__c;
                                tp.hed__StartDate__c = System.today();
                                tp.hed__Status__c = 'Active';
                                tp.hed__Primary__c = true;
                                tp.Marketo_Created__c = true;
                                tp.RecordTypeId = devRecordTypeId;

                                affiliations.add(tp);
                            }
                        }
                    }
                    else if(mrk.primaryAttributeValue == '2nd CAP/Academic Partner Referral'){
                        //t.Created_By_Marketo_Integration__c = true;
                        t.CAP_Field_Update__c = '2nd CAP/Academic Partner Referral';
                        for(MRK_TaskModel.Attribute at : mrk.attributes){
                            if(at.name == 'Old Value'){
                                t.Marketo_Previous__c = at.value;
                            }
                            if(at.name == 'New Value'){
                                t.Marketo_Next__c = at.value;
                            }
                        }

                        if(t.whoId != null && String.valueOf(t.WhoId).startswith('003')){
                            Set<Id> accSet = contoAff.get(t.whoId);
                            if(accSet != null && !accSet.contains(t.Marketo_Next__c)){
                                hed__Affiliation__c tp = new hed__Affiliation__c();
                                tp.hed__Contact__c = t.whoId;
                                tp.hed__Account__c = t.Marketo_Next__c;
                                tp.hed__StartDate__c = System.today();
                                tp.hed__Status__c = 'Active';
                                tp.hed__Primary__c = false;
                                tp.Marketo_Created__c = true;
                                tp.RecordTypeId = devRecordTypeId;
            
                                affiliations.add(tp);
                            }
                            else if(accSet == null){
                                hed__Affiliation__c tp = new hed__Affiliation__c();
                                tp.hed__Contact__c = t.whoId;
                                tp.hed__Account__c = t.Marketo_Next__c;
                                tp.hed__StartDate__c = System.today();
                                tp.hed__Status__c = 'Active';
                                tp.hed__Primary__c = false;
                                tp.Marketo_Created__c = true;
                                tp.RecordTypeId = devRecordTypeId;

                                affiliations.add(tp);
                            }
                        }
                    }

                    tasks.add(t);
                }
            }

            List<Task> failed = new List<Task>();
            
            if(!tasks.isEmpty()){
                Schema.SObjectField ftoken = Task.Fields.Marketo_Activity_Id__c;
                Database.UpsertResult[] srList = Database.upsert(tasks,ftoken,false);
                Integer i = 0;
                for (Database.UpsertResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully inserted:: ' + sr.getId());
                    }
                    else {
                        failed.add(tasks[i]);
                    }
                    i++;
                }

                if(!failed.isEmpty() && ml.Id == null){
                    ml.Number_Of_Retries__c = 0;
                    ml.Include_in_Retries__c = false;
                    ml.Marketo_CMDT_Id__c = mt.Id;
                    ml.Object_Api__c = 'Task';
                    ml.External_Id__c = 'Marketo_Activity_Id__c';
                    ml.Status__c = 'Fail';
                    ml.DML_Error__c = true;
                    
                    MRK_LoggerHelper.insertLog(JSON.serialize(failed), mt, ml);
                }
                else{
                    ml.Number_Of_Retries__c = ml.Number_Of_Retries__c + 1;
                    ml.Include_in_Retries__c = false;
                    ml.Status__c = 'Success';
                }
            }

            System.debug(affiliations);
            if(!affiliations.isEmpty()){
                processAffiliationUpdates(affiliations, devRecordTypeId);
            }
        }
        return ml;
    }

    public static void processAffiliationUpdates(List<hed__Affiliation__c> affiliations, Id devRecordTypeId){
        List<Id> newAffs = new List<Id>();
        List<hed__Affiliation__c> affLst = new List<hed__Affiliation__c>();
        List<hed__Affiliation__c> affLstPrimaryChange = new List<hed__Affiliation__c>();

        Database.SaveResult[] srList =  Database.insert(affiliations,false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully inserted:: ' + sr.getId());
                newAffs.add(sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }

        if(!newAffs.isEmpty()){
            List<hed__Affiliation__c> affs = [SELECT Id, RecordTypeId, Marketo_Static_List_IdF__c, Marketo_Contact_Id__c, hed__Primary__c, hed__Account__c 
                                                FROM hed__Affiliation__c 
                                                WHERE Id IN: newAffs];

            for(hed__Affiliation__c aff : affs){
                if(aff.RecordTypeId == devRecordTypeId && aff.Marketo_Static_List_IdF__c != null && aff.Marketo_Contact_Id__c != null){
                    affLst.add(aff);
                }
                if(aff.hed__Primary__c){
                    affLstPrimaryChange.add(aff);
                }
            }

            if(!affLstPrimaryChange.isEmpty() || !affLst.isEmpty()){
                ID jobID = System.enqueueJob(new MRK_TriggerCalloutHelper(affLst, new List<sObject>(), 'hed__Affiliation__c', 'Insert', affLstPrimaryChange));
            }
        }
    }

    public static Map<String,String> getExternalIdMap(String ExternalIdField, String objectStr, List<String> leadIds){
        Map<String, String> mapOfExternalIdRefs = new Map<String,String>();
        for(sObject obj : Database.query('SELECT Id, ' + ExternalIdField + ' FROM ' + objectStr + ' WHERE ' + ExternalIdField + ' IN: leadIds')){
            mapOfExternalIdRefs.put(String.ValueOf(obj.get(ExternalIdField)), String.ValueOf(obj.get('Id')));
        }

        return mapOfExternalIdRefs;
    }

    public static MRK_Payload_Parser__mdt getActivityTypes(){
        return [SELECT Id, json__c FROM MRK_Payload_Parser__mdt WHERE DeveloperName = 'Activity_Map' limit 1];
    }

    public static Map<String,String> getAllEmailTemps(){
        Map<String,String> emTemps = new Map<String,String>();
        for(EmailTemplate et : [SELECT Id, Name, FolderName, IsActive FROM EmailTemplate WHERE IsActive = true AND Folder.DeveloperName = 'MarketoEmailTemplates' ORDER BY CreatedDate ASC]){
            emTemps.put(et.Name, et.Id);
        }

        return emTemps;
    }

    public static Map<Id, Set<Id>> currentAff(List<Id> conIds){
        Map<Id, Set<Id>> contoAff = new Map<Id, Set<Id>>();
        for(hed__Affiliation__c aff : [SELECT Id,hed__Contact__c,hed__Account__c FROM hed__Affiliation__c WHERE hed__Contact__c IN: conIds]){
            if(contoAff.containsKey(aff.hed__Contact__c)){
                Set<Id> accSet = contoAff.get(aff.hed__Contact__c);
                accSet.add(aff.hed__Account__c);
                contoAff.put(aff.hed__Contact__c, accSet);
            }
            else{
                contoAff.put(aff.hed__Contact__c, new Set<Id>{aff.hed__Account__c});
            }
        }

        return contoAff;
    }

}