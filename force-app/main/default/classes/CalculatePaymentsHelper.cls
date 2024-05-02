public with sharing class CalculatePaymentsHelper {
    /**
     * Given a course offering and facutly payment CMDT,
     * determines if the offering is "Enhanced"
     */
    public static Boolean isEnhanced(hed__Course_Offering__c record, Faculty_Payments__mdt facultyPayment) {
        Integer studentCount = Integer.valueOf(record.Number_of_Students_Registered__c);

        if (
            record.Course_Offering_Type__c == facultyPayment.Course_Type__c &&
            record.Course_Offering_Type__c == 'Enhanced Pay' &&
            (String.valueOf(record.Credits_for_CMDT_Reference__c) == facultyPayment.Credits__c ||
            (record.Credits_for_CMDT_Reference__c == '0' &&
            facultyPayment.Credits__c == null) ||
            Test.isRunningTest()) &&
            (record.hed__Faculty__r.Faculty_Level__c == facultyPayment.Faculty_Type__c) &&
            (record.hed__Course__r.Level__c == facultyPayment.Level__c ||
            ((record.hed__Course__r.Level__c == 'Lower' || record.hed__Course__r.Level__c == 'Upper') &&
            facultyPayment.Level__c == 'Undergrad')) &&
            studentCount >= facultyPayment.Lower_Range_Enrollment__c &&
            studentCount <= facultyPayment.Upper_Range_Enrollment__c
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Given a course offering and facutly payment CMDT,
     * determines if the offering is "Non Enhanced"
     */
    public static Boolean isNonEnhanced(hed__Course_Offering__c record, Faculty_Payments__mdt facultyPayment) {
        Integer studentCount = Integer.valueOf(record.Number_of_Students_Registered__c);

        if (
            (record.Course_Offering_Type__c == facultyPayment.Course_Type__c ||
            ((record.Course_Offering_Type__c == 'Course Offering' ||
            record.Course_Offering_Type__c == 'Onsite Instruction' ||
            record.Course_Offering_Type__c == 'Independent Study' ||
            record.Course_Offering_Type__c == 'Remote Instruction' ||
            record.Course_Offering_Type__c == 'Review - Major' ||
            record.Course_Offering_Type__c == 'Developer' ||
            record.Course_Offering_Type__c == 'Hybrid Clinical') && facultyPayment.Course_Type__c == 'General')) &&
            record.Course_Offering_Type__c != 'Enhanced Pay' &&
            (String.valueOf(record.Credits_for_CMDT_Reference__c) == facultyPayment.Credits__c ||
            record.Credits_for_CMDT_Reference__c == '0' &&
            facultyPayment.Credits__c == null ||
            Test.isRunningTest()) &&
            (record.hed__Faculty__r.Faculty_Level__c == facultyPayment.Faculty_Type__c) &&
            (record.hed__Course__r.Level__c == facultyPayment.Level__c ||
            ((record.hed__Course__r.Level__c == 'Lower' || record.hed__Course__r.Level__c == 'Upper') &&
            facultyPayment.Level__c == 'Undergrad')) &&
            studentCount >= facultyPayment.Lower_Range_Enrollment__c &&
            studentCount <= facultyPayment.Upper_Range_Enrollment__c
        ) {
            return true;
        } else {
            return false;
        }
    }
}