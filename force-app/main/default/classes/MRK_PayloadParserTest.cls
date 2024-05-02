@isTest
public class MRK_PayloadParserTest {
    @isTest
    static void runTests() {

		MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Example6' limit 1];

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

        String payload = '{'+
		'  \"id\": \"5\",'+
		'  \"first_name\": \"John\",'+
		'  \"last_name\": \"Doe\",'+
		'  \"family\": ['+
		'    { \"first_name\": \"Jane\", \"last_name\": \"Doe\" },'+
		'	{ \"first_name\": \"Mary\", \"last_name\": \"Doe\" },'+
		'	{ \"first_name\": \"Steve\", \"last_name\": \"Doe\" }'+
		'  ],'+
		'  \"company\": {'+
		'    \"name\": \"Acme Corp\",'+
		'	\"address\": \"123 Fake St. Rochester, NY 14424\"'+
		'  }'+
        '}';

        MRK_PayloadParser.processData('Example6', payload,ml);
    }

	@isTest
    static void runTests2() {

		MRK_Payload_Parser__mdt mr = [SELECT Id, End_Point_Url__c, json__c, push_json__c, Qualified_Objects__c,DeveloperName,Utilize_Dynamic__c,
        Sync_Fields__c, Sync_Object__c, Sync_Type__c, Sync_Field_Map__c,Run_Every_min__c 
        FROM MRK_Payload_Parser__mdt WHERE DeveloperName =: 'Example3' limit 1];

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

        String payload = '{'+
		'  \"id\": \"5\",'+
		'  \"first_name\": \"John\",'+
		'  \"last_name\": \"Doe\",'+
		'  \"family\": ['+
		'    { \"first_name\": \"Jane\", \"last_name\": \"Doe\" },'+
		'	{ \"first_name\": \"Mary\", \"last_name\": \"Doe\" },'+
		'	{ \"first_name\": \"Steve\", \"last_name\": \"Doe\" }'+
		'  ],'+
		'  \"company\": {'+
		'    \"name\": \"Acme Corp\",'+
		'	\"address\": \"123 Fake St. Rochester, NY 14424\"'+
		'  }'+
        '}';

        MRK_PayloadParser.processData('Example3', payload,ml);
    }

	@isTest
    static void runTests3() {
		String JSONContent =
			'{"person":{' + 
				'"name":"John Smith",' +
				'"phone":"555-1212"}}';
		JSONParser parser = 
		JSON.createParser(JSONContent);
		Test.startTest();
		MRK_MetaDTO.consumeObject(parser);
		Test.stopTest();
	}

	@isTest
    static void runTests4() {
		String JSONContent =
			'{"person":{' + 
				'"name":"John Smith",' +
				'"phone":"555-1212"}}';
		JSONParser parser = 
		JSON.createParser(JSONContent);
		Test.startTest();
		MRK_MetaDTO.mapStringToString(parser);
		Test.stopTest();
	}

	@isTest
    static void runTests5() {
		String JSONContent ='';
		JSONParser parser = 
		JSON.createParser(JSONContent);
		Test.startTest();
		MRK_MetaDTO.getGMTDate(System.now());
		Test.stopTest();
	}

	@isTest
    static void runTests6() {
		String JSONContent =
			'{"person":{' + 
				'"name":"John Smith",' +
				'"phone":"555-1212"}}';
		JSONParser parser = 
		JSON.createParser(JSONContent);
		Test.startTest();
		//MRK_MetaDTO.arrayOfString(parser);
		Test.stopTest();
	}
}