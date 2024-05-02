global class CalculatePaymentsBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Id clinicalExaminations;
    public List<Faculty_Payments__mdt> facultyPaymentsTypes;
    public Date today;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id courseOfferingRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
            .get('Course Offering')
            .getRecordTypeId();

        Id hybridClinicalRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName()
            .get('Hybrid Clinical')
            .getRecordTypeId();

        List<Id> offeringRecordTypeIds = new List<Id>{ courseOfferingRecordTypeId, hybridClinicalRecordTypeId };

        facultyPaymentsTypes = [
            SELECT
                Id,
                DeveloperName,
                Additional_Pay__c,
                Course_Type__c,
                Credits__c,
                Faculty_Type__c,
                Fee_Type__c,
                Flat_Fee__c,
                Level__c,
                Lower_Range_Enrollment__c,
                Upper_Range_Enrollment__c
            FROM Faculty_Payments__mdt
        ];
        today = Date.today();

        Custom_Calculation_Date_Offset__c offset = Custom_Calculation_Date_Offset__c.getOrgDefaults();
        String query =
            'SELECT Id, Course_Offering_Type__c, Credit_Hours__c, hed__Course__r.Level__c, hed__Faculty__r.Faculty_Level__c, hed__Start_Date__c, Compensation__c, Bi_Weekly_Compensation__c, ' +
            'Number_of_Students_Registered__c, Credits_for_CMDT_Reference__c, Payday_Calculation__c, RecordType.Name, Number_of_Bi_Weekly_Payments__c, Bi_weekly_payments_start__c ' +
            'FROM hed__Course_Offering__c WHERE (RecordTypeId IN :offeringRecordTypeIds) AND Status__c = \'Active\' AND Faculty_Load_Type__c != \'On Load\'';
        if (!Test.isRunningTest()) {
            query += ' AND (Bi_weekly_payments_start__c =: today)';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<hed__Course_Offering__c> records) {
        CheckBatch.alreadyRunningBatch = true;
        CheckRecursive.runBefore = false;
        CheckRecursive.runAfter = false;

        List<Payment__c> existingPayments = [
            SELECT Id, Course_Offering__c
            FROM Payment__c
            WHERE Course_Offering__c IN :records
        ];

        // Populate CourseOfferingPaymentsMap
        Map<Id, Payment__c> courseOfferingPaymentsMap = new Map<Id, Payment__c>();
        for (Integer i = 0; i < records.size(); i++) {
            for (Payment__c payment : existingPayments) {
                if (payment.Course_Offering__c == records[i].Id) {
                    courseOfferingPaymentsMap.put(records[i].Id, payment);
                }
            }
        }

        // Update compensation values for each offering
        List<hed__Course_Offering__c> courseOfferingsToUpdate = new List<hed__Course_Offering__c>();
        for (hed__Course_Offering__c record : records) {
            if (courseOfferingPaymentsMap.get(record.Id) == null) {
                Integer studentCount = Integer.valueOf(record.Number_of_Students_Registered__c);

                for (Faculty_Payments__mdt facultyPayment : facultyPaymentsTypes) {
                    Boolean isEnhanced = CalculatePaymentsHelper.isEnhanced(record, facultyPayment);
                    Boolean isNonEnhanced = CalculatePaymentsHelper.isNonEnhanced(record, facultyPayment);

                    if (isEnhanced || isNonEnhanced) {
                        Double standardPaymentAmount;
                        if (facultyPayment.Fee_Type__c == 'Per') {
                            standardPaymentAmount = studentCount * Double.valueOf(facultyPayment.Flat_Fee__c);
                        }
                        if (facultyPayment.Fee_Type__c == 'Flat') {
                            standardPaymentAmount = Double.valueOf(facultyPayment.Flat_Fee__c);
                        }

                        // when enhanced we add in the extra pay
                        if (isEnhanced) {
                            standardPaymentAmount += Double.valueOf(facultyPayment.Additional_Pay__c);
                        }

                        record.Compensation__c = standardPaymentAmount;
                        record.First_Payment_Calculated__c = true;
                        record.Number_of_Students_Registered_on_Day_4__c = studentCount;
                        courseOfferingsToUpdate.add(record);

                        break;
                    }
                }
            }
        }

        Database.update(courseOfferingsToUpdate);

        String query =
            'SELECT Id, Course_Offering_Type__c, Credit_Hours__c, hed__Course__r.Level__c, hed__Faculty__r.Faculty_Level__c, hed__Start_Date__c, Compensation__c, Bi_Weekly_Compensation__c, ' +
            'Number_of_Students_Registered__c, Credits_for_CMDT_Reference__c, Payday_Calculation__c, RecordType.Name, Number_of_Bi_Weekly_Payments__c, Bi_weekly_payments_start__c ' +
            'FROM hed__Course_Offering__c WHERE Id IN :courseOfferingsToUpdate';

        // create the payments
        List<Payment__c> paymentsToInsert = new List<Payment__c>();
        for (hed__Course_Offering__c courseOffering : Database.query(query)) {
            // Check courseOfferingPaymentsMap to see if a payment record already exists, and skip if so
            if (
                courseOfferingPaymentsMap.get(courseOffering.Id) == null &&
                courseOffering.Compensation__c != null &&
                courseOffering.Compensation__c != 0
            ) {
                for (Integer i = 0; i < courseOffering.Number_of_Bi_Weekly_Payments__c; i++) {
                    Payment__c newPayment = new Payment__c();
                    newPayment.Course_Offering__c = courseOffering.Id;
                    newPayment.Payment_Date__c = courseOffering.Payday_Calculation__c.addDays(i * 14);
                    newPayment.Payment_Amount__c = courseOffering.Bi_Weekly_Compensation__c;
                    newPayment.Pay_To__c = courseOffering.hed__Faculty__c;

                    paymentsToInsert.add(newPayment);
                }
            }
        }

        Database.insert(paymentsToInsert);
    }

    global void finish(Database.BatchableContext bc) {
    }
}