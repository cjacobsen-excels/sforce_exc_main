public class NewEdContactTriggerHandler {

    public static DateTime lastDupeMergeProcess {
        get {
            if(lastDupeMergeProcess == null) {
                lastDupeMergeProcess = DateTime.now();
            }
            return lastDupeMergeProcess;
        }
        set;
    }
    
    public static void handle() {
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
            	dupeMerge((List<NewEd__Contact_Info__c>)Trigger.new, new Map<Id, NewEd__Contact_Info__c>());
            }
            else if(Trigger.isUpdate) {
            	dupeMerge((List<NewEd__Contact_Info__c>)Trigger.new, (Map<Id, NewEd__Contact_Info__c>)Trigger.oldMap);
            }
        }
    }
    
    public static void dupeMerge(List<NewEd__Contact_Info__c> newRecords, Map<Id, NewEd__Contact_Info__c> oldRecordsMap) {
        
        List<NewEd__Contact_Info__c> affectedRecords = new List<NewEd__Contact_Info__c>();
        
        for(NewEd__Contact_Info__c ci : newRecords) {
            if(ci.Dupe_Match_Key__c != null && (Trigger.isInsert || ci.Dupe_Match_Key__c != oldRecordsMap.get(ci.Id).Dupe_Match_Key__c)) {
                affectedRecords.add(ci);
            }
        }
        
        // requery contact info records so we have related / updated data
        List<NewEd__Contact_Info__c> contactInfos = [select
            Id,
            NewEd__First_Name__c,
            NewEd__Last_Name__c,
            NewEd__Email__c,
            Dupe_Match_Key__c,
            Student__c,
            Student__r.Id,
            Student__r.FirstName,
            Student__r.LastName,
            Student__r.Email
            from
            NewEd__Contact_Info__c where Id in :affectedRecords
        ];
        system.debug('contactInfos: ' + contactInfos);
        
        Map<String, NewEd__Contact_Info__c> contactInfosByDupeMatchKey = new Map<String, NewEd__Contact_Info__c>();
        String dupeKey;

        for(NewEd__Contact_Info__c ci : contactInfos) {
            system.debug(ci);
            dupeKey = ci.Dupe_Match_Key__c.trim();
            if(dupeKey == '') continue;
            system.debug('contactInfosByKey key :: ' + dupeKey);
            system.debug('contactInfosByKey value :: ' + ci);
            contactInfosByDupeMatchKey.put(dupeKey, ci);
        }

        // load Contact_Match__c records with related Contact records
        // filter using dupe match keys from NewEd__Contact_Info__c records
        List<Contact_Match__c> contactMatches = [select
            Id,
            Match_Key__c,
            Contact_ID__c,
            Contact_ID__r.Id,
            Contact_ID__r.FirstName,
            Contact_ID__r.LastName,
            Contact_ID__r.Email
            from Contact_Match__c 
            where Match_Key__c in :contactInfosByDupeMatchKey.keySet()
            and Contact_ID__c != null
        ];
        system.debug('contactMatches: ' + contactMatches);

        // build a map of contact by key, based on related contact_match__c record
        Map<String, Contact> contactsByDupeMatchKey = new Map<String, Contact>();

        for(Contact_Match__c cm : contactMatches) {
            dupeKey = cm.Match_Key__c.trim();
            if(dupeKey == '') continue;
            contactsByDupeMatchKey.put(dupeKey, cm.Contact_ID__r);
        }
        system.debug('contactsByDupeMatchKey :: ' + contactsByDupeMatchKey);

        Map<Id, Contact> contactsById = new Map<Id, Contact>(contactsByDupeMatchKey.values());

        // associate contact matches' contacts with matching newed contact infos
        for(NewEd__Contact_Info__c ci : contactInfos) {
            dupeKey = ci.Dupe_Match_Key__c;
            if(contactsByDupeMatchKey.containsKey(dupeKey)) {
                ci.Student__c = contactsByDupeMatchKey.get(dupeKey).Id;
            }
        }

        List<Contact> newStudentRecords = new List<Contact>();
        List<Contact> existingStudentRecords = new List<Contact>();
        
        Contact studentRecord;
        Id studentRecordId;

        Map<Id, Contact> contactsByContactInfoId = new Map<Id, Contact>();

        for(NewEd__Contact_Info__c ci : contactInfos) {
            
            system.debug(ci);
            system.debug(ci.Student__r);
            
            studentRecordId = ci.Student__c;            
            
            if(studentRecordId != null) {

                studentRecord = new Contact(Id = studentRecordId);
                // RA 2016-06-01 - unit test was not maintaining this relationship - we only need to "bump" an existing contact to have process builder fire on it
                // RA 2016-05-23 - reference directly from contactInfo
                // studentRecord = ci.Student__r;
                //studentRecord = contactsById.get(studentRecordId);
                existingStudentRecords.add(studentRecord);
            }
            else {
                studentRecord = new Contact(
                    FirstName = ci.NewEd__First_Name__c,
                    LastName = ci.NewEd__Last_Name__c,
                    Email = ci.NewEd__Email__c
                );      
                newStudentRecords.add(studentRecord);
            }

            contactsByContactInfoId.put(ci.Id, studentRecord);

        }

        system.debug('existingStudentRecords :: ' + existingStudentRecords);
        system.debug('newStudentRecords :: ' + newStudentRecords);
        
        NewEd.Util.doUpdate(existingStudentRecords);
        NewEd.Util.doInsert(newStudentRecords);
        
        for(NewEd__Contact_Info__c ci : contactInfos) {
            ci.Student__c = contactsByContactInfoId.get(ci.Id).Id;
            ci.Last_Dupe_Merge_Process__c = lastDupeMergeProcess;
        }

        NewEd.Util.doUpdate(contactInfos);
        NewEd.Util.insertLogs();

    }
    
}