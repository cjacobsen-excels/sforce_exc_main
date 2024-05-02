@isTest
global class MRK_MockCalloutTest implements HttpCalloutMock {

	// Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        String authStr = '{"access_token":"test"}';
		String activities = '{"requestId":"d1bd#177f9e1bed9","result":[{"id":26078865,"marketoGUID":"26078865","leadId":452323,"activityDate":"2021-03-30T20:59:54Z","activityTypeId":13,"primaryAttributeValueId":914,"primaryAttributeValue":"2nd CAP/Academic Partner Referral","attributes":[{"name":"New Value","value":"001U000000hOBamIAG"},{"name":"Old Value","value":null},{"name":"Reason","value":"Form fill-out, URL: http://na-ab01.marketo.com/lp/400-LAE-932/NM-Email-Test_NM-LP-Test.html"},{"name":"Source","value":"Web form fillout"}]},{"id":26078865,"marketoGUID":"26078865","leadId":452323,"activityDate":"2021-03-30T20:59:54Z","activityTypeId":13,"primaryAttributeValueId":914,"primaryAttributeValue":"CAP/Academic Partner Referral","attributes":[{"name":"New Value","value":"001U000000hOBamIAG"},{"name":"Old Value","value":null},{"name":"Reason","value":"Form fill-out, URL: http://na-ab01.marketo.com/lp/400-LAE-932/NM-Email-Test_NM-LP-Test.html"},{"name":"Source","value":"Web form fillout"}]},{"id":57,"marketoGUID":"57","leadId":1539,"activityDate":"2021-03-03T20:53:59Z","activityTypeId":6,"campaignId":7240,"primaryAttributeValueId":3,"primaryAttributeValue":"VC_Test","attributes":[{"name":"Campaign Run ID","value":18},{"name":"Choice Number","value":0},{"name":"Step ID","value":30285},{"name":"Campaign","value":"Run Action Send Email 2021-03-03 12:53:39 pm"}]}],"success":true,"nextPageToken":"ZCFNHFY3D6KM5VVC752BLBOFGFV7QDI7IHM3KG4EANM5DSW5SLQA====","moreResult":false}';
        String staticLists = '{"success":true,"errors":[],"requestId":"7a92#177f9c424d6","warnings":[],"result":[{"id":1614,"name":"New IMB","createdAt":"2021-03-03T20:25:17Z+0000","updatedAt":"2021-03-03T20:25:17Z+0000","folder":{"id":609,"type":"Folder"},"computedUrl":"https://app-ab28.marketo.com/#ST1614A1","workspace":"Outreach & Access"}]}';
        String leads = '{"requestId":"116a6#177f9d32a9e","result":[{"id":1539,"sfdcId":null,"X2nd_Acad_Corp_Part_Ref__c":"001g000002UcoIWAAZ","Acad_Corp_Part_Ref__c":"001g000002UcoIWAAZ","sfdcContactId":"003g0000027vIfvAAE"}],"success":true}';
		String pageToke = '{"requestId":"12596#177f9d98b38","success":true,"nextPageToken":"WOJQJZUS4MQIRSQELXF6JTLWSBT255BDZCGITTJ6ZKUABZG5K2FA===="}';

		String pageToke2 = '{"requestId":"12596#177f9d98b38","success":false,"nextPageToken":"WOJQJZUS4MQIRSQELXF6JTLWSBT255BDZCGITTJ6ZKUABZG5K2FA===="}';

        HttpResponse res = new HttpResponse();
		if(req.getEndpoint().contains('activities') && !req.getEndpoint().contains('sinceDatetime')){
			res.setHeader('Content-Type', 'application/json');
			res.setBody(activities);
			res.setStatusCode(200);
        }
        if(req.getEndpoint().contains('staticLists')){
			res.setHeader('Content-Type', 'application/json');
			res.setBody(staticLists);
			res.setStatusCode(200);
        }

        if(req.getEndpoint().contains('leads')){
			res.setHeader('Content-Type', 'application/json');
			res.setBody(leads);
			res.setStatusCode(200);
        }

        if(req.getEndpoint().contains('client_credentials')){
			res.setHeader('Content-Type', 'application/json');
			res.setBody(authStr);
			res.setStatusCode(200);
        }

		if(req.getEndpoint().contains('sinceDatetime')){
			res.setHeader('Content-Type', 'application/json');
			res.setBody(authStr);
			res.setStatusCode(200);
        }

		if(req.getEndpoint().contains('fail')){
			res.setHeader('Content-Type', 'application/json');
			res.setBody(pageToke2);
			res.setStatusCode(200);
        }
        
        return res;
    }
}