public class MRK_SessionHandler {
    public String accessToken;
	public Marketo_Api_Settings__c loginSettings;

	public MRK_SessionHandler(){
		loginSettings = Marketo_Api_Settings__c.getOrgDefaults();
		Map<String, String> authResponse = new Map<String, String>();

		System.debug(loginSettings);

		authResponse = (Map<String, String>)JSON.deserialize(
				authenticate(loginSettings.Auth_Url__c, loginSettings.client_id__c,
							loginSettings.secret_id__c),
					Map<String, String>.class
				);
		System.debug(authResponse);
		accessToken = authResponse.get('access_token');
	}

	public MRK_SessionResponseModel getRequest(string body, String url, string type){
		MRK_SessionResponseModel sessionResponse = new MRK_SessionResponseModel();
		System.debug(body);
		System.debug(accessToken);
		String responseBody = '';
		try {
            HttpRequest request = new HttpRequest();
            request.setMethod(type);
			request.setEndpoint(loginSettings.Request_Url__c + url);

			System.debug(loginSettings.Request_Url__c + url);

			request.setHeader('Authorization', 'Bearer ' + accessToken);
			if(url.contains('staticLists') && type == 'POST'){
				request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
				request.setBody(body);
			}
			else if(type != 'GET'){
				request.setHeader('Content-Type', 'application/json');
				request.setBody(body.removeStart('[').removeEnd(']'));
			}
			//request.setHeader('accept', 'application/json');

            HttpResponse response = new Http().send(request);

			System.debug(response);
			//formate Response
			responseBody = response.getBody();
			System.debug(responseBody);
			for(String resp : responseBody.split(',')){
				System.debug(resp);
			}
            //responseBody = responseBody.removeStart('[').removeEnd(']');

			sessionResponse.statusCode = response.getStatusCode();
			sessionResponse.Message = responseBody;
			sessionResponse.reqMessage = request;
			sessionResponse.resMessage = response;

			if(responseBody.contains('"success":false')){
				Marketo_Log__c ml = new Marketo_Log__c();
				ml.Start_Date__c = System.now();
				ml.End_Date__c = System.now();
				ml.Status__c = 'Fail';
				ml.Number_Of_Retries__c = 0;
				ml.Include_in_Retries__c = false;
				//ml.Marketo_CMDT_Id__c = url;
				ml.Response__c = responseBody.length() > 20001 ? responseBody.substring(0,20000) + ' \n .... Response Trimmed' : responseBody;
				ml.Request__c = url;

				insert ml;
			}

        } catch (Exception e){
			System.debug('Error: ' + e.getMessage());
			Marketo_Log__c ml = new Marketo_Log__c();
			ml.Start_Date__c = System.now();
			ml.End_Date__c = System.now();
			ml.Status__c = 'Fail';
			ml.Number_Of_Retries__c = 0;
			ml.Include_in_Retries__c = false;
			//ml.Marketo_CMDT_Id__c = url;
			ml.Response__c = responseBody.length() > 20001 ? responseBody.substring(0,20000) + ' \n .... Response Trimmed' : responseBody;
			ml.Request__c = url;
			ml.Error_Message__c = 'Error: ' + e.getMessage();

			insert ml;
        }
		return sessionResponse;
	}

	@TestVisible
    private String authenticate(String url, String clientId, String clientSecret) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(url + '?grant_type=client_credentials&client_id='+clientId+'&client_secret='+clientSecret);
		HttpResponse resp = new Http().send(request);

		String retuenVal = resp.getBody();
        return retuenVal;
	}
	
	public class RespModel{
        public boolean success;
        public string nextPageToken;
        public string requestId;
        public boolean moreResult;
    }
}