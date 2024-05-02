@isTest
public class CalculatePaymentsBatchTest {
    private static Id courseOfferingId;
    private static Id hybridOfferingId;
    private static Id courseDevelopersMajorReviewsRecordTypeId;
    private static Account testAccount;
    private static hed__Course__c course;
    private static Contact faculty;
    private static Training_Assignments__c assignment;
    private static Qualified_Faculty__c qualifiedFaculty;
    private static hed__Course_Offering__c courseOffering;

    @isTest
    static void testBatchSchedulable() {
        String courseLevel = 'Upper';
        setup(courseLevel);

        Training_Assignments__c assignment = createTraining('FERPA', 'Completed');
        Training_Assignments__c assignment2 = createTraining('Sexual Harrasment', 'Completed');
        hed__Term__c testTerm = createTerm(null);
        hed__Term__c testTerm2 = createTerm(testTerm.Id);
        hed__Term__c testTerm3 = createTerm(testTerm2.Id);

        Integer creditHours = 1;
        String courseOfferingType = 'Onsite Instruction';
        courseOffering = createCourseOffering(testTerm3.Id, creditHours, courseOfferingId, courseOfferingType);

        String CRON_EXP = '0 0 0 15 3 ? 2023';
        Test.startTest();
        String jobId = System.schedule(
            'CalculatePaymentsBatchSchedulableTest',
            CRON_EXP,
            new CalculatePaymentsBatchSchedulable()
        );

        Database.executeBatch(new CalculatePaymentsBatch());
        Test.stopTest();
    }

    @isTest
    static void testBatchSchedulableEnhanced() {
        String courseLevel = 'Lower';
        setup(courseLevel);

        Training_Assignments__c assignment = createTraining('FERPA', 'Completed');
        Training_Assignments__c assignment2 = createTraining('Sexual Harrasment', 'Completed');

        hed__Term__c testTerm = createTerm(null);
        hed__Term__c testTerm2 = createTerm(testTerm.Id);
        hed__Term__c testTerm3 = createTerm(testTerm2.Id);

        Integer creditHours = 6;
        String courseOfferingType = 'Enhanced Pay';
        courseOffering = createCourseOffering(testTerm3.Id, creditHours, courseOfferingId, courseOfferingType);

        String CRON_EXP = '0 0 0 15 3 ? 2023';
        Test.startTest();
        String jobId = System.schedule(
            'CalculatePaymentsBatchSchedulableTest',
            CRON_EXP,
            new CalculatePaymentsBatchSchedulable()
        );

        Database.executeBatch(new CalculatePaymentsBatch());
        Test.stopTest();
    }

    @isTest
    static void testHybridOffering() {
        String courseLevel = 'Lower';
        setup(courseLevel);

        Training_Assignments__c assignment = createTraining('FERPA', 'Completed');
        Training_Assignments__c assignment2 = createTraining('Sexual Harrasment', 'Completed');

        hed__Term__c testTerm = createTerm(null);
        hed__Term__c testTerm2 = createTerm(testTerm.Id);
        hed__Term__c testTerm3 = createTerm(testTerm2.Id);

        Integer creditHours = 6;
        String courseOfferingType = 'Hybrid Clinical';
        courseOffering = createCourseOffering(testTerm3.Id, creditHours, hybridOfferingId, courseOfferingType);

        String CRON_EXP = '0 0 0 15 3 ? 2023';
        Test.startTest();
        String jobId = System.schedule(
            'CalculatePaymentsBatchSchedulableTest',
            CRON_EXP,
            new CalculatePaymentsBatchSchedulable()
        );

        Database.executeBatch(new CalculatePaymentsBatch());
        Test.stopTest();
    }

    /**
     * HELPERS
     */

    private static void setup(String courseLevel) {
        courseOfferingId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
            .get('Course Offering')
            .getRecordTypeId();

        hybridOfferingId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
            .get('Hybrid Clinical')
            .getRecordTypeId();
        System.assert(hybridOfferingId != null);
        courseDevelopersMajorReviewsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
            .get('Course Developers & Major Reviews')
            .getRecordTypeId();

        testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;

        course = new hed__Course__c();
        course.Level__c = courseLevel;
        course.hed__Account__c = testAccount.Id;
        insert course;

        faculty = new Contact();
        faculty.LastName = 'test contact';
        faculty.Faculty_Level__c = 'Standard';
        faculty.hed__FERPA__c = true;
        faculty.Faculty_Status__c = 'Active';
        insert faculty;

        // for validation rules
        Training_Assignments__c fac100Training = createTraining('FAC 100', 'Completed');

        qualifiedFaculty = new Qualified_Faculty__c();
        qualifiedFaculty.Course__c = course.Id;
        qualifiedFaculty.Faculty__c = faculty.Id;
        insert qualifiedFaculty;
    }

    private static Training_Assignments__c createTraining(String trainingType, String status) {
        Training_Assignments__c trainingAssignment = new Training_Assignments__c();
        trainingAssignment.Faculty_Contact__c = faculty.Id;
        trainingAssignment.Training_Type__c = trainingType;
        trainingAssignment.Status__c = status;
        trainingAssignment.Completed_Date__c = System.today().addDays(-2);
        insert trainingAssignment;
        return trainingAssignment;
    }

    private static hed__Term__c createTerm(Id parentId) {
        hed__Term__c term = new hed__Term__c();
        term.Name = 'Test';
        term.hed__Account__c = testAccount.Id;
        term.hed__Start_Date__c = Date.today();
        term.hed__End_Date__c = Date.today().addDays(56);
        term.hed__Type__c = 'Term 1';

        if (parentId != null) {
            term.hed__Parent_Term__c = parentId;
        }

        insert term;
        return term;
    }

    private static hed__Course_Offering__c createCourseOffering(
        Id termId,
        Integer creditHours,
        Id recordTypeId,
        String offeringType
    ) {
        hed__Course_Offering__c courseOffering = new hed__Course_Offering__c();
        courseOffering.Name = 'super rad name';
        courseOffering.RecordTypeId = recordTypeId;
        courseOffering.hed__Course__c = course.Id;
        courseOffering.Bi_weekly_payments_start__c = Date.today();
        courseOffering.hed__Term__c = termId;
        courseOffering.Credit_Hours__c = creditHours;
        courseOffering.Number_of_Students_Registered__c = 6;
        courseOffering.Course_Offering_Type__c = offeringType;
        courseOffering.Status__c = 'Active';

        // process builder or other trigger will bomb out if this is hybrid clinical
        // try removing this check and run tests, if nothing blows up remove this conditional check
        if (offeringType != 'Hybrid Clinical') {
            courseOffering.Qualified_Faculty__c = qualifiedFaculty.Id;
        }

        System.debug(courseOffering);
        insert courseOffering;
        return courseOffering;
    }
}