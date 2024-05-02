@IsTest
public class MRK_ProjectTest {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    public static testMethod void testAffAndContactTrigger(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        List<hed__Affiliation__c> affLstPrimaryChange = new List<hed__Affiliation__c>();
        List<hed__Affiliation__c> affLst = new List<hed__Affiliation__c>();
        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(Marketo_Created__c = false, hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        affLst.add(a);
        //affLstPrimaryChange.add(a);

        ID jobID = System.enqueueJob(new MRK_TriggerCalloutHelper(affLst, new List<sObject>(), 'hed__Affiliation__c', 'Insert', affLstPrimaryChange));
        Test.StopTest();
    }

    public static testMethod void testAffAndContactTrigger2(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Example2' limit 1];

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        hed__Affiliation__c a = new hed__Affiliation__c(Marketo_Created__c = false, hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        List<hed__Affiliation__c> affLstPrimaryChange = new List<hed__Affiliation__c>();
        List<hed__Affiliation__c> affLst = new List<hed__Affiliation__c>();

        a.hed__Primary__c = true;
        update a;

        MRK_CalloutHelper.replaceMergeFields(a, mr);

        Test.StartTest();

        affLstPrimaryChange.add(a);

        ID jobID = System.enqueueJob(new MRK_SyncMarketoCapFields(affLstPrimaryChange));
        Test.StopTest();
    }

    public static testMethod void testAffAndContactTrigger3(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Example4' limit 1];

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        List<hed__Affiliation__c> affLstPrimaryChange = new List<hed__Affiliation__c>();
        List<hed__Affiliation__c> affLst = new List<hed__Affiliation__c>();
        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(Marketo_Created__c = true, hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        MRK_CalloutHelper.getRecord(mr);

        a.hed__Primary__c = true;
        a.Mrk_Sync_Id__c = '12543';

        affLst.add(a);

        ID jobID = System.enqueueJob(new MRK_TriggerCalloutHelper(new List<sObject>(), affLst, 'hed__Affiliation__c', 'Insert', affLstPrimaryChange));
        update a;
        Test.StopTest();
    }

    public static testMethod void testAffAndContactTrigger4(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        delete a;
        Test.StopTest();
    }

    public static testMethod void testAffAndContactSyncBatch(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        String jobId = System.schedule('MRK_MarketoSyncScheduleTest',
            CRON_EXP,
            new MRK_MarketoSyncSchedule());
        Test.StopTest();

        Contact asl = [SELECT Id, Marketo_Sync__c FROM Contact WHERE Id =: a.hed__Contact__c limit 1];

        System.assertEquals(asl.Marketo_Sync__c, false);
    }

    public static testMethod void testAffAndContactSyncBatch2(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        List<MRK_Payload_Parser__mdt> listVar = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c
        FROM MRK_Payload_Parser__mdt WHERE Include_In_Main_Sync__c = true AND Is_Active__c = true AND Is_Url_Merge__c = false];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now().addDays(-1);
				ml.End_Date__c = System.now().addDays(-1);
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = listVar[0].Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '';
				ml.Request__c = '';
        insert ml;

        Marketo_Log__c ml2 = new Marketo_Log__c();
				ml2.Start_Date__c = System.now().addDays(-2);
				ml2.End_Date__c = System.now().addDays(-2);
				ml2.Status__c = 'Fail';
				ml2.Number_Of_Retries__c = 0;
				ml2.Include_in_Retries__c = false;
                ml2.DML_Error__c = true;
                ml2.Object_Api__c = 'Task';
				ml2.Marketo_CMDT_Id__c = listVar[0].Id;
                ml2.External_Id__c = 'Marketo_Activity_Id__c';
				ml2.Response__c = '';
				ml2.Request__c = '';
        insert ml2;

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        String jobId = System.schedule('MRK_MarketoSyncScheduleTest',
            CRON_EXP,
            new MRK_MarketoSyncSchedule());
        Test.StopTest();

        Contact asl = [SELECT Id, Marketo_Sync__c FROM Contact WHERE Id =: a.hed__Contact__c limit 1];

        System.assertEquals(asl.Marketo_Sync__c, false);
    }

    public static testMethod void testAffAndContactMultiPullBatch(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Sync__c = true;
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
        testContact2.Marketo_Sync__c = true;
        testContact2.Marketo_Id__c = '1111234';
		insert testContact2;

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        hed__Affiliation__c a2 = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '1254312', hed__account__c = testAccount.Id, hed__Contact__c = testContact2.Id, RecordTypeId = devRecordTypeId);
		Insert a2;

        testContact.Marketo_Sync__c = true;
        update testContact;

        testContact2.Marketo_Sync__c = true;
        update testContact2;

        String jobId = System.schedule('MRK_MultiPullMarketoScheduleTest',
            CRON_EXP,
            new MRK_MultiPullMarketoSchedule());
        Test.StopTest();

        Contact asl = [SELECT Id, Marketo_Sync__c FROM Contact WHERE Id =: a.hed__Contact__c limit 1];

        //System.assertEquals(asl.Marketo_Sync__c, false);
    }

    public static testMethod void testAffAndContactRetry(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Get_Activities' limit 1];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = mr.Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '{"id":26319623,"marketoGUID":"26319623","leadId":1419206,"activityDate":"2021-04-05T14:40:38Z","activityTypeId":6,"campaignId":2154,"primaryAttributeValueId":1113,"primaryAttributeValue":"SBT BACH CYBER Communication Plan.SBT BACH CYBER CP 1 Knowledge is Power Program Focus","attributes":[{"name":"Campaign Run ID","value":145},{"name":"Choice Number","value":0},{"name":"Step ID","value":7998},{"name":"Campaign","value":"NM Test All.test 4.5.21 Courtney Partner"}]}';
				ml.Request__c = '';

        Marketo_Log__c l = MRK_LoggerHelper.insertLog('[{"attributes":{"type":"Task"},"Marketo_Activity_Id__c":"123456789","Subject":"Email Was Clicked on","Description":"Wmail Message","WhoId":"003g0000027vIfvAAE","Status":"Completed"}]', mr, ml);

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        String jobId = System.schedule('MRK_RetryEntryScheduleTest',
            CRON_EXP,
            new MRK_RetryEntrySchedule());
        Test.StopTest();

        
    }

    public static testMethod void testAffAndContactRetry2(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Get_Activities' limit 1];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = mr.Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '{"id":26319623,"marketoGUID":"26319623","leadId":1419206,"activityDate":"2021-04-05T14:40:38Z","activityTypeId":6,"campaignId":2154,"primaryAttributeValueId":1113,"primaryAttributeValue":"SBT BACH CYBER Communication Plan.SBT BACH CYBER CP 1 Knowledge is Power Program Focus","attributes":[{"name":"Campaign Run ID","value":145},{"name":"Choice Number","value":0},{"name":"Step ID","value":7998},{"name":"Campaign","value":"NM Test All.test 4.5.21 Courtney Partner"}]}';
				ml.Request__c = '';

        Marketo_Log__c l = MRK_LoggerHelper.insertLog('[{"attributes":{"type":"Task"}}]', mr, ml);

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        String jobId = System.schedule('MRK_RetryEntryScheduleTest',
            CRON_EXP,
            new MRK_RetryEntrySchedule());
        Test.StopTest();

        
    }

    public static testMethod void testAffAndContactRetry3(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Get_Activities' limit 1];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = mr.Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '{"id":26319623,"marketoGUID":"26319623","leadId":1419206,"activityDate":"2021-04-05T14:40:38Z","activityTypeId":6,"campaignId":2154,"primaryAttributeValueId":1113,"primaryAttributeValue":"SBT BACH CYBER Communication Plan.SBT BACH CYBER CP 1 Knowledge is Power Program Focus","attributes":[{"name":"Campaign Run ID","value":145},{"name":"Choice Number","value":0},{"name":"Step ID","value":7998},{"name":"Campaign","value":"NM Test All.test 4.5.21 Courtney Partner"}]}';
				ml.Request__c = '';

        insert ml;
        ContentVersion cv = new ContentVersion();
            cv.Title = 'Log Body';
            cv.PathOnClient = 'marketoLog.txt';
            cv.VersionData = Blob.valueOf('[{"attributes":{"type":"Task"}}]');
            cv.IsMajorVersion = true;
            cv.FirstPublishLocationId = ml.Id;
            Database.insert(cv,false);

        //Marketo_Log__c l = MRK_LoggerHelper.insertLog('[{"attributes":{"type":"Task"}}]', mr, ml);

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        String jobId = System.schedule('MRK_RetryEntryScheduleTest',
            CRON_EXP,
            new MRK_RetryEntrySchedule());
        Test.StopTest();

        
    }

    public static testMethod void testClearLogs(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Get_Activities' limit 1];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = mr.Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '';
				ml.Request__c = '';

        Marketo_Log__c l = MRK_LoggerHelper.insertLog('[{"attributes":{"type":"Task"}}]', mr, ml);

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId);
		Insert a;

        String jobId = System.schedule('MRK_ClearLogsScheduleTest',
            CRON_EXP,
            new MRK_ClearLogsSchedule());
        Test.StopTest();

        
    }

    public static testMethod void testCreateStatic(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
		insert testAccount;

        Test.StartTest();

        String jobId = System.schedule('MRK_CreateStaticListsScheduleTest',
            CRON_EXP,
            new MRK_CreateStaticListsSchedule());
        Test.StopTest();

        
    }

    public static testMethod void testCreateStaticTrigger(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Test.StartTest();

        Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
		insert testAccount;

        Test.StopTest();

        
    }

    public static testMethod void testCreateStaticTrigger2(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
		insert testAccount;

        Test.StartTest();

        testAccount.POP_Code__c = '1234';
        update testAccount;

        Test.StopTest();

        
    }

    public static testMethod void testClearLog(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        
        Marketo_Log__c ml = new Marketo_Log__c();
        ml.Start_Date__c = System.now();
        ml.End_Date__c = System.now();
        ml.Status__c = 'Fail';
        ml.Number_Of_Retries__c = 0;
        ml.Include_in_Retries__c = false;
        ml.Response__c = 'test';
        ml.Request__c = 'test';

        insert ml;

        Test.setCreatedDate(ml.Id, DateTime.newInstance(2012,12,12));
        
        Test.starttest();
        MRK_ClearLogsBatch b = new MRK_ClearLogsBatch(); 
        Database.executebatch(b, 10);
        Test.stoptest();
    }

    public static testMethod void testInterfaceController(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Marketo_Api_Settings__c csMrk = Marketo_Api_Settings__c.getOrgDefaults();
        Test.starttest();
        MRK_InterfaceController.getSettings();
        MRK_InterfaceController.getMDTSetting();
        MRK_InterfaceController.setSettings(JSON.serialize(csMrk));
        Test.stoptest();
    }

    public static testMethod void testLogsClass(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        
        Marketo_Log__c ml = new Marketo_Log__c();
        ml.Start_Date__c = System.now();
        ml.End_Date__c = System.now();
        ml.Status__c = 'Fail';
        ml.Number_Of_Retries__c = 0;
        ml.Include_in_Retries__c = false;
        ml.Response__c = 'test';
        ml.Request__c = 'test';

        insert ml;

        Marketo_Log__c ml2 = new Marketo_Log__c();
        ml2.Start_Date__c = System.now();
        ml2.End_Date__c = System.now();
        ml2.Status__c = 'Success';
        ml2.Number_Of_Retries__c = 0;
        ml2.Include_in_Retries__c = false;
        ml2.Response__c = 'test';
        ml2.Request__c = 'test';

        Marketo_Log__c ml3 = new Marketo_Log__c();
        ml3.Start_Date__c = System.now();
        ml3.End_Date__c = System.now();
        ml3.Status__c = 'Fail';
        ml3.Number_Of_Retries__c = 0;
        ml3.Include_in_Retries__c = false;
        ml3.Response__c = 'test';
        ml3.Request__c = 'test';

        Test.starttest();
        MRK_LoggerHelper.getLog(ml.Id);
        MRK_LoggerHelper.createLog('Test', true, 1, 'test', 'test', 'Fail');
        MRK_LoggerHelper.updateLog(ml.Id, 'Test', true, 1, 'test', 'test', 'Fail');
        MRK_LoggerHelper.notify(ml2);
        MRK_LoggerHelper.notify(ml3);
        Test.stoptest();
    }

    public static testMethod void testList(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Marketo_Api_Settings__c csMrk = Marketo_Api_Settings__c.getOrgDefaults();

        Marketo_Log__c ml = new Marketo_Log__c();
        ml.Start_Date__c = System.now();
        ml.End_Date__c = System.now();
        ml.Status__c = 'Fail';
        ml.Number_Of_Retries__c = 0;
        ml.Include_in_Retries__c = false;
        ml.Response__c = 'test';
        ml.Request__c = 'test';

        insert ml;

        Marketo_Log__c ml2 = new Marketo_Log__c();
        ml2.Start_Date__c = System.now();
        ml2.End_Date__c = System.now();
        ml2.Status__c = 'Success';
        ml2.Number_Of_Retries__c = 0;
        ml2.Include_in_Retries__c = false;
        ml2.Response__c = 'test';
        ml2.Request__c = 'test';
        insert ml2;

        Marketo_Log__c ml3 = new Marketo_Log__c();
        ml3.Start_Date__c = System.now();
        ml3.End_Date__c = System.now();
        ml3.Status__c = 'Fail';
        ml3.Number_Of_Retries__c = 0;
        ml3.Include_in_Retries__c = false;
        ml3.Response__c = 'test';
        ml3.Request__c = 'test';
        insert ml3;

        List<sObject> setObj = new List<sObject>();
        setObj.add(ml);
        setObj.add(ml2);
        setObj.add(ml3);

        Test.starttest();
        MRK_Lists.doPartions(setObj, 2, List<List<sObject>>.class);
        Test.stoptest();
    }

    public static testMethod void testSessionResponseModel(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Marketo_Api_Settings__c csMrk = Marketo_Api_Settings__c.getOrgDefaults();
        Test.starttest();
        MRK_SessionResponseModel cm = new MRK_SessionResponseModel();
        cm.Message = 'test';
        cm.ErrorCode = 'test';
        cm.Status = 'Succes';
        cm.StatusReason = 'test';
        cm.statusCode = 200;

        cm.isSuccess();
        Test.stoptest();
    }

    public static testMethod void testRemoveAffFromStaticListSchedule(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Get_Activities' limit 1];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = mr.Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '';
				ml.Request__c = '';

        Marketo_Log__c l = MRK_LoggerHelper.insertLog('[{"attributes":{"type":"Task"}}]', mr, ml);

        Test.StartTest();
		hed__Affiliation__c a = new hed__Affiliation__c(hed__Primary__c = true, Mrk_Sync_Id__c = '12543', hed__account__c = testAccount.Id, hed__Contact__c = testContact.Id, RecordTypeId = devRecordTypeId, hed__EndDate__c = System.today().addDays(-2), Mrk_Removed_From_Static_List__c = false);
		Insert a;

        String jobId = System.schedule('MRK_RemoveAffFromStaticListScheduleTest',
            CRON_EXP,
            new MRK_RemoveAffFromStaticListSchedule());
        Test.StopTest();
    }

    public static testMethod void testMultiTest1(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Example_5' limit 1];
        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = mr.Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '';
				ml.Request__c = '';

                insert ml;

        Test.starttest();
        MRK_AffiliationModel af = new MRK_AffiliationModel();
        af.id_z = 'test';
        af.X2nd_Acad_Corp_Part_Ref = 'test';
        af.Acad_Corp_Part_Ref = 'test';
        af.sfdcContactId = 'test';
        af.sfdcLeadId = 'test';

        MRK_MultiPullMarketoBatch.getLogs();
        MRK_MultiPullMarketoSchedule.getLogs();
        MRK_MultiPullMarketoBatch.processBody(mr);
        MRK_MarketoSyncBatch.processBody(mr);
        MRK_MultiPullMarketoBatch.getGMTDate(System.now());

        MRK_SessionHandler sh = new MRK_SessionHandler();
        sh.getRequest('', '', null);
        Test.stoptest();
    }

    public static testMethod void multiPageTest(){
        Test.setMock(HttpCalloutMock.class, new MRK_MockCalloutTest());
        Id devRecordTypeId = Schema.SObjectType.hed__Affiliation__c.getRecordTypeInfosByName().get('Student Partner Affiliation').getRecordTypeId();
        Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        List<MRK_Payload_Parser__mdt> listVar = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c
        FROM MRK_Payload_Parser__mdt WHERE Include_In_Main_Sync__c = true AND Is_Active__c = true AND Is_Url_Merge__c = false];

        Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now().addDays(-1);
				ml.End_Date__c = System.now().addDays(-1);
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
                ml.DML_Error__c = true;
                ml.Object_Api__c = 'Task';
				ml.Marketo_CMDT_Id__c = listVar[0].Id;
                ml.External_Id__c = 'Marketo_Activity_Id__c';
				ml.Response__c = '';
				ml.Request__c = '';
        insert ml;

        Marketo_Log__c ml2 = new Marketo_Log__c();
				ml2.Start_Date__c = System.now().addDays(-2);
				ml2.End_Date__c = System.now().addDays(-2);
				ml2.Status__c = 'Fail';
				ml2.Number_Of_Retries__c = 0;
				ml2.Include_in_Retries__c = false;
                ml2.DML_Error__c = true;
                ml2.Object_Api__c = 'Task';
				ml2.Marketo_CMDT_Id__c = listVar[0].Id;
                ml2.External_Id__c = 'Marketo_Activity_Id__c';
				ml2.Response__c = '';
				ml2.Request__c = '';
        insert ml2;

		Account testAccount = new Account();
		testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = devRecordTypeId2;
        testAccount.POP_Code__c = '1234';
        testAccount.Marketo_Static_List_Id__c = '12345';
		insert testAccount;

		Contact testContact= new Contact();
		testContact.LastName= 'testlast';
        testContact.Marketo_Id__c = '452323';
		insert testContact;

		Contact testContact2= new Contact();
		testContact2.LastName= 'testlast';
		insert testContact2;

        Test.StartTest();

        MRK_SessionHandler sh = new MRK_SessionHandler();
        System.enqueueJob(new MRK_PageTokenCalloutQueueable(sh, '', 'https://400-LAE-932.mktorest.com/rest/v1/activities.json?activityTypeIds=2,6,7,10,11,13&nextPageToken=YKLUULTVEM5LR4YIM4F2WOI32CFP3WAU7YU2W4XYKJLWYNAQ7FPA====', listVar[0], '', ml2));
        Test.StopTest();
    }
}