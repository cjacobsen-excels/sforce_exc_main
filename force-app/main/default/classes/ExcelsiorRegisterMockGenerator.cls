/**
 * @description     HTTP Mock for callouts
 * @author          Meghna Vijay, Traction On Demand
 * @date            2021-06-24
 */

@isTest
global class ExcelsiorRegisterMockGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        String recaptchaResponse = '{"success": true}';
        res.setHeader('Content-Type', 'application/json');
        res.setBody(recaptchaResponse);
        res.setStatusCode(200);
        return res;
    }
}