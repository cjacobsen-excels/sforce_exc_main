@isTest
private class ChatterAnswersEscalationTriggerTest {
    static testMethod void validateQuestionEscalation() {
        String questionTitle = 'questionTitle';
        String questionBody = 'questionBody';
        Community[] c = [SELECT Id from Community WHERE isActive=True];
        // We cannot create a question without a community
        if (c.size() == 0) { return; }
        String communityId = c[0].Id;
        Question q = new Question();
        q.Title = questionTitle;
        q.Body = questionBody;
        q.CommunityId = communityId;
        insert(q);
        q.Priority = 'high';
        try{
            update(q);
        }
        catch(Exception e) {
            String bodyText = 'Case Escalation on Question having ID: ' + q.Id + ' has failed with the following message: ' + e.getMessage() +
                '\n\nStacktrace: ' + e.getStacktraceString();
            System.assertNotEquals(bodyText,'test');
            System.assert(e.getMessage().contains('Update failed.'), e.getMessage()); 
            //System.assertEquals(toAddresses, toAddresses);
        }
    }
}