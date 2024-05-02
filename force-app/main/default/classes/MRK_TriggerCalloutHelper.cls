public class MRK_TriggerCalloutHelper implements Queueable, Database.AllowsCallouts {

    public List<sObject> addObjects;
    public List<sObject> delObjects;
    public String objectStr;
    public String typeReq;
    List<hed__Affiliation__c> capFieldobjects;

    public MRK_TriggerCalloutHelper(List<sObject> addObjects, List<sObject> delObjects, String objectStr, String typeReq, List<hed__Affiliation__c> capFieldobjects) {
        this.addObjects = addObjects;
        this.delObjects = delObjects;
        this.objectStr = objectStr;
        this.typeReq = typeReq;
        this.capFieldobjects = capFieldobjects;
    }

    public void execute(QueueableContext context) {
        if(objectStr == 'hed__Affiliation__c'){

            if(!addObjects.isEmpty()){
                List<String> requests = processTriggerReturn(addObjects);

                if(!requests.isEmpty()){
                    MRK_SessionHandler sh = new MRK_SessionHandler();
                    for(String req : requests){
                        System.debug(req);
                        sh.getRequest('', req, 'POST');
                    }
                }
            }
            if(!delObjects.isEmpty()){
                List<String> requests = processTriggerReturn(delObjects);

                if(!requests.isEmpty()){
                    MRK_SessionHandler sh = new MRK_SessionHandler();
                    for(String req : requests){
                        System.debug(req);
                        sh.getRequest('', req, 'DELETE');
                    }
                }
            }
        }
        
        if(!capFieldobjects.isEmpty() && !Test.isRunningTest()){
            ID jobID = System.enqueueJob(new MRK_SyncMarketoCapFields(capFieldobjects));
        }
    }

    public static Map<String, List<sObject>> getMapOfContacts(List<sObject> objectsLst){
        Map<String, List<sObject>> objMap = new Map<String, List<sObject>>();
        for(sObject obj : objectsLst){
            if(objMap.containsKey(String.valueOf(obj.get('Marketo_Static_List_IdF__c')))){
                List<sObject> ojbLst = objMap.get(String.valueOf(obj.get('Marketo_Static_List_IdF__c')));
                ojbLst.add(obj);
                objMap.put(String.valueOf(obj.get('Marketo_Static_List_IdF__c')),ojbLst);
            }
            else{
                objMap.put(String.valueOf(obj.get('Marketo_Static_List_IdF__c')), new List<sObject>{obj});
            }
        }

        return objMap;
    }

    public static string createUrl(List<sObject> setObj){
        string urlreq = '';
        Integer i = 0;
        for(sObject obj : setObj){
            if(i == 0){
                urlreq += 'id='+obj.get('Marketo_Contact_Id__c');
            }
            else{
                urlreq += '&id='+obj.get('Marketo_Contact_Id__c');
            }
        }

        return urlreq;
    }

    public static List<String> processTriggerReturn(List<sObject> objectsLst){
        Map<String, List<sObject>> markLst = getMapOfContacts(objectsLst);
        List<String> requests = new List<String>();
        for(String obj : markLst.keyset()){
            string requestUrl = '/v1/lists/'+obj+'/leads.json?';
            List<sObject> setObj = markLst.get(obj);
            if(setObj != null && setObj.size() <= 300){
                requestUrl += createUrl(setObj);
                requests.add(requestUrl);
            }
            else if(setObj != null && setObj.size() >= 300){
                List<List<sObject>> actual = (List<List<sObject>>) MRK_Lists.doPartions(setObj, 300, List<List<sObject>>.class);
                for(List<sObject> smallList : actual){
                    requestUrl += createUrl(smallList);
                    requests.add(requestUrl);
                }
            }
        }

        return requests;
    }
}