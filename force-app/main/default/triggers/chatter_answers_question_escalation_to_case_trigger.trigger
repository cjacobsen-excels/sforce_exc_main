trigger chatter_answers_question_escalation_to_case_trigger on Question (after update) {

    if(Trigger.isAfter && Trigger.isUpdate){
        chatterAnswersQuestionEscalationService.chatterAnswerQuestions(Trigger.new, Trigger.oldMap);
        chatterAnswersQuestionEscalationService.testchatterAnswerQuestionsErrorHandling(Trigger.new, Trigger.oldMap);
    }
}