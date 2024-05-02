@isTest
public class CourseOfferingTriggerTest {
  @TestSetup
  static void setupTests() {
    Id courseOfferingRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
      .get('Course Offering')
      .getRecordTypeId();
    Id courseDevelopersMajorReviewsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
      .get('Course Developers & Major Reviews')
      .getRecordTypeId();
    Id independentStudyRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
      .get('Independent Study')
      .getRecordTypeId();
    // Id clinicalExaminationsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
    //   .get('Clinical Examinations')
    //   .getRecordTypeId();

    Account testAccount = new Account();
    testAccount.Name = 'Test Account';
    insert testAccount;

    Account testAccount2 = new Account();
    testAccount2.Name = 'Test Account';
    insert testAccount2;

    Account testAccount3 = new Account();
    testAccount3.Name = 'Test Account';
    insert testAccount3;

    Contact faculty = new Contact();
    faculty.LastName = 'test faculty contact';
    faculty.Faculty_Level__c = 'Standard';
    faculty.CE_Faculty__c = true;
    insert faculty;

    hed__Facility__c hospitalFacility = new hed__Facility__c();
    hospitalFacility.hed__Facility_Type__c = 'Hospital';
    insert hospitalFacility;

    hed__Course__c course = new hed__Course__c();
    course.Level__c = 'Graduate';
    course.hed__Account__c = testAccount.Id;
    course.Facility__c = hospitalFacility.Id;
    // course.CE__c = true;
    insert course;

    hed__Course__c course2 = new hed__Course__c();
    course2.Level__c = 'Graduate';
    course2.hed__Account__c = testAccount2.Id;
    insert course2;

    hed__Course__c course3 = new hed__Course__c();
    course3.Level__c = 'Lower';
    course3.hed__Account__c = testAccount3.Id;
    insert course3;

    hed__Term__c testTerm = new hed__Term__c();
    testTerm.hed__Account__c = testAccount.Id;
    testTerm.hed__Type__c = 'Term 2';
    insert testTerm;

    hed__Term__c testTerm2 = new hed__Term__c();
    testTerm2.hed__Account__c = testAccount2.Id;
    testTerm2.hed__Type__c = 'Term 2';
    insert testTerm2;

    hed__Term__c testTerm3 = new hed__Term__c();
    testTerm3.hed__Account__c = testAccount3.Id;
    testTerm3.hed__Type__c = 'Term 2';
    insert testTerm3;

    hed__Course_Offering__c courseOffering = new hed__Course_Offering__c();
    courseOffering.RecordTypeId = courseOfferingRecordTypeId;
    courseOffering.Name = 'Test 1';
    courseOffering.hed__Course__c = course2.Id;
    courseOffering.Bi_weekly_payments_start__c = Date.today();
    courseOffering.Number_of_Students_Registered__c = 6;
    courseOffering.hed__Term__c = testTerm.Id;
    courseOffering.Credit_Hours__c = 1;
    courseOffering.hed__Faculty__c = faculty.Id;
    insert courseOffering;

    // hed__Course_Offering__c clinicalExaminations = new hed__Course_Offering__c();
    // clinicalExaminations.RecordTypeId = clinicalExaminationsRecordTypeId;
    // clinicalExaminations.Name = 'Test 1';
    // clinicalExaminations.Number_of_Students_Registered__c = 12;
    // clinicalExaminations.hed__Course__c = course.Id;
    // clinicalExaminations.Bi_weekly_payments_start__c = Date.today();
    // clinicalExaminations.hed__Term__c = testTerm.Id;
    // clinicalExaminations.Credit_Hours__c = 1;
    // clinicalExaminations.Course_Offering_Type__c = 'Full Exam';
    // clinicalExaminations.hed__Course__c = course.Id;
    // insert clinicalExaminations;

    hed__Course_Offering__c courseOfferingDevelopersMajorReviews = new hed__Course_Offering__c();
    courseOfferingDevelopersMajorReviews.RecordTypeId = courseDevelopersMajorReviewsRecordTypeId;
    courseOfferingDevelopersMajorReviews.Name = 'Test 2';
    courseOfferingDevelopersMajorReviews.hed__Course__c = course2.Id;
    courseOfferingDevelopersMajorReviews.Bi_weekly_payments_start__c = Date.today();
    courseOfferingDevelopersMajorReviews.hed__Term__c = testTerm2.Id;
    courseOfferingDevelopersMajorReviews.Number_of_Students_Registered__c = 6;
    courseOfferingDevelopersMajorReviews.Credit_Hours__c = 1;
    courseOfferingDevelopersMajorReviews.Contract_Hours__c = 4;
    courseOfferingDevelopersMajorReviews.Course_Offering_Type__c = 'Review - Major';
    courseOfferingDevelopersMajorReviews.hed__Faculty__c = faculty.Id;
    courseOfferingDevelopersMajorReviews.Faculty_Load_Type__c = 'Off Load';
    insert courseOfferingDevelopersMajorReviews;

    hed__Course_Offering__c independentStudy = new hed__Course_Offering__c();
    independentStudy.RecordTypeId = independentStudyRecordTypeId;
    independentStudy.Name = 'Test 3';
    independentStudy.hed__Course__c = course3.Id;
    independentStudy.Number_of_Students_Registered__c = 6;
    independentStudy.Bi_weekly_payments_start__c = Date.today();
    independentStudy.hed__Term__c = testTerm3.Id;
    independentStudy.Credit_Hours__c = 1;
    independentStudy.hed__Faculty__c = faculty.Id;
    independentStudy.Course_Offering_Type__c = 'Independent Study';
    independentStudy.hed__Faculty__c = faculty.Id;
    independentStudy.Faculty_Load_Type__c = 'Off Load';
    insert independentStudy;

    CheckRecursive.runBefore = true;
    CheckRecursive.runAfter = true;
  }

  @isTest
  static void independentStudyTest() {
    Id independentStudyRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
      .get('Independent Study')
      .getRecordTypeId();
    hed__Course_Offering__c courseOffering = [
      SELECT Id
      FROM hed__Course_Offering__c
      WHERE RecordTypeId = :independentStudyRecordTypeId
    ];
    courseOffering.Compensation__c = 1000;
    Test.startTest();
    update courseOffering;
    Test.stopTest();
  }
  @isTest
  static void courseDevelopersTest() {
    Id courseDevelopersMajorReviewsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
      .get('Course Developers & Major Reviews')
      .getRecordTypeId();
    hed__Course_Offering__c courseOffering = [
      SELECT Id
      FROM hed__Course_Offering__c
      WHERE RecordTypeId = :courseDevelopersMajorReviewsRecordTypeId
    ];
    courseOffering.Compensation__c = 1000;
    Test.startTest();
    update courseOffering;
    Test.stopTest();
  }
  @isTest
  static void courseOfferingTest() {
    Id courseOfferingRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
      .get('Course Offering')
      .getRecordTypeId();
    hed__Course_Offering__c courseOffering = [
      SELECT Id
      FROM hed__Course_Offering__c
      WHERE RecordTypeId = :courseOfferingRecordTypeId
    ];
    courseOffering.Compensation__c = 1000;
    Test.startTest();
    update courseOffering;
    Test.stopTest();
  }
  // @isTest
  // static void clinicalExaminationsTest1() {
  //   Id clinicalExaminationsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
  //     .get('Clinical Examinations')
  //     .getRecordTypeId();
  //   hed__Course_Offering__c courseOffering = [
  //     SELECT Id, Status__c
  //     FROM hed__Course_Offering__c
  //     WHERE RecordTypeId = :clinicalExaminationsRecordTypeId AND Name = 'Test 1'
  //   ];
  //   courseOffering.Compensation__c = 1000;
  //   Contact faculty = [SELECT Id FROM Contact WHERE Name = 'test faculty contact'];

  //   Test.startTest();
  //   hed__Course_Enrollment__c courseConnection = new hed__Course_Enrollment__c();
  //   courseConnection.hed__Course_Offering__c = courseOffering.Id;
  //   courseConnection.Role__c = 'Clinical Examiner';
  //   courseConnection.hed__Contact__c = faculty.Id;
  //   courseConnection.Phase__c = '1';
  //   courseConnection.hed__Status__c = 'Confirmed';
  //   insert courseConnection;
  //   CheckRecursive.runBefore = true;
  //   CheckRecursive.runAfter = true;
  //   update courseOffering;
  //   Test.stopTest();
  // }

  // @isTest
  // static void clinicalExaminationsTest2() {
  //   Id clinicalExaminationsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
  //     .get('Clinical Examinations')
  //     .getRecordTypeId();
  //   hed__Course_Offering__c courseOffering = [
  //     SELECT Id, Status__c
  //     FROM hed__Course_Offering__c
  //     WHERE RecordTypeId = :clinicalExaminationsRecordTypeId AND Name = 'Test 1'
  //   ];
  //   courseOffering.Compensation__c = 1000;
  //   courseOffering.Status__c = 'Completed';
  //   Contact faculty = [SELECT Id FROM Contact WHERE Name = 'test faculty contact'];

  //   Test.startTest();
  //   hed__Course_Enrollment__c courseConnection = new hed__Course_Enrollment__c();
  //   courseConnection.hed__Course_Offering__c = courseOffering.Id;
  //   courseConnection.Role__c = 'Clinical Examiner';
  //   courseConnection.hed__Contact__c = faculty.Id;

  //   courseConnection.Phase__c = '1';
  //   courseConnection.hed__Status__c = 'Confirmed';
  //   insert courseConnection;
  //   CheckRecursive.runBefore = true;
  //   CheckRecursive.runAfter = true;
  //   update courseOffering;
  //   Test.stopTest();
  // }

  // @isTest
  // static void clinicalExaminationsTest3() {
  //   Id clinicalExaminationsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
  //     .get('Clinical Examinations')
  //     .getRecordTypeId();
  //   hed__Course_Offering__c courseOffering = [
  //     SELECT Id, Status__c
  //     FROM hed__Course_Offering__c
  //     WHERE RecordTypeId = :clinicalExaminationsRecordTypeId AND Name = 'Test 1'
  //   ];

  //   Contact faculty = [SELECT Id FROM Contact WHERE Name = 'test faculty contact'];

  //   Test.startTest();
  //   hed__Course_Enrollment__c courseConnection2 = new hed__Course_Enrollment__c();
  //   courseConnection2.hed__Course_Offering__c = courseOffering.Id;
  //   courseConnection2.Role__c = 'Clinical Associate';
  //   courseConnection2.hed__Contact__c = faculty.Id;
  //   courseConnection2.hed__Status__c = 'Confirmed';
  //   insert courseConnection2;
  //   courseOffering.Compensation__c = 1000;
  //   courseOffering.CET3__c = 2;
  //   CheckRecursive.runBefore = true;
  //   CheckRecursive.runAfter = true;
  //   update courseOffering;
  //   Test.stopTest();
  // }

  // @isTest
  // static void clinicalExaminationsTest4() {
  //   Id clinicalExaminationsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
  //     .get('Clinical Examinations')
  //     .getRecordTypeId();
  //   hed__Course_Offering__c courseOffering = [
  //     SELECT Id, Status__c
  //     FROM hed__Course_Offering__c
  //     WHERE RecordTypeId = :clinicalExaminationsRecordTypeId AND Name = 'Test 1'
  //   ];

  //   Contact faculty = [SELECT Id FROM Contact WHERE Name = 'test faculty contact'];

  //   Test.startTest();
  //   hed__Course_Enrollment__c courseConnection2 = new hed__Course_Enrollment__c();
  //   courseConnection2.hed__Course_Offering__c = courseOffering.Id;
  //   courseConnection2.Role__c = 'Clinical Associate';
  //   courseConnection2.hed__Contact__c = faculty.Id;
  //   courseConnection2.hed__Status__c = 'Confirmed';
  //   insert courseConnection2;

  //   courseOffering.Status__c = 'Completed';
  //   courseOffering.Compensation__c = 1000;
  //   courseOffering.CET3__c = 2;
  //   CheckRecursive.runAfter = true;
  //   update courseOffering;
  //   Test.stopTest();
  // }

  // @isTest
  // static void clinicalExaminationsTest5() {
  //   Id clinicalExaminationsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
  //     .get('Clinical Examinations')
  //     .getRecordTypeId();
  //   hed__Course_Offering__c courseOffering = [
  //     SELECT Id, Status__c
  //     FROM hed__Course_Offering__c
  //     WHERE RecordTypeId = :clinicalExaminationsRecordTypeId AND Name = 'Test 1'
  //   ];

  //   Contact faculty = [SELECT Id FROM Contact WHERE Name = 'test faculty contact'];

  //   Test.startTest();
  //   hed__Course_Enrollment__c courseConnection2 = new hed__Course_Enrollment__c();
  //   courseConnection2.hed__Course_Offering__c = courseOffering.Id;
  //   courseConnection2.Role__c = 'Clinical Associate';
  //   courseConnection2.hed__Contact__c = faculty.Id;
  //   courseConnection2.hed__Status__c = 'Confirmed';
  //   insert courseConnection2;

  //   courseOffering.Status__c = 'Completed';
  //   courseOffering.Compensation__c = 1000;
  //   courseOffering.CET3__c = 2;
  //   CheckRecursive.runBefore = true;
  //   update courseOffering;
  //   Test.stopTest();
  // }
}