public with sharing class chatterAnswersQuestionEscalationService {
	public static void chatterAnswerQuestions(List<Question> newQuestions, Map<Id, Question> questionToIdMap){
				for (Question q: newQuestions) {
	            if (q.Priority == 'high' && (q.Cases == null || q.Cases.size() == 0) && questionToIdMap.get(q.id).Priority != 'high') {
	                q = [select Id, Title, Body, CommunityId, createdById, createdBy.AccountId, createdBy.ContactId from Question where Id = :q.Id];
	                Case newCase = new Case(Origin='Chatter Answers', OwnerId=q.CreatedById, QuestionId=q.Id, CommunityId=q.CommunityId, Subject=q.Title, Description = (q.Body == null? null: q.Body.stripHtmlTags()), AccountId=q.CreatedBy.AccountId, ContactId=q.CreatedBy.ContactId);
	                insert newCase;
	            }
	    }
	}

	public static void testchatterAnswerQuestionsErrorHandling(List<Question> newQuestions, Map<Id, Question> questionToIdMap){
				for (Question q: newQuestions) {
	        try {
	            if (q.Priority == 'high' && (q.Cases == null || q.Cases.size() == 0) && questionToIdMap.get(q.id).Priority != 'high') {
	                q = [select Id, Title, Body, CommunityId, createdById, createdBy.AccountId, createdBy.ContactId from Question where Id = :q.Id];
	                Case newCase1 = new Case(Origin='Chatter Answers', OwnerId=q.CreatedById, QuestionId='test', CommunityId=q.CommunityId, Subject=q.Title, Description = (q.Body == null? null: q.Body.stripHtmlTags()), AccountId=q.CreatedBy.AccountId, ContactId=q.CreatedBy.ContactId);
	                insert newCase1;
	            }
	        } catch (Exception e) {
	            String subjectText = 'Case Escalation exception in site ' + Site.getName();
	            String bodyText = 'Case Escalation on Question having ID: ' + q.Id + ' has failed with the following message: ' + e.getMessage() +
	                '\n\nStacktrace: ' + e.getStacktraceString();

	            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	            String[] toAddresses = new String[] { Site.getAdminEmail() };

	            mail.setReplyTo('no-reply@salesforce.com');
	            mail.setSenderDisplayName('Salesforce Chatter Answers User');

	            // The default sender is the portal user causing this trigger to run, to change this, set an organization-wide address for
	            // the portal user profile, and set the ID in the following line.
	            // mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
	            mail.setToAddresses(toAddresses);
	            mail.setSubject(subjectText);
	            mail.setPlainTextBody(bodyText);
	            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	        }
	    }
	}
}