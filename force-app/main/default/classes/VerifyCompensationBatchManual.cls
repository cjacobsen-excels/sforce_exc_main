global class VerifyCompensationBatchManual implements Database.Batchable<sObject>, Database.Stateful {
    public Id courseOfferingRecordTypeId;
    public List<Id> courseOfferingIds;
    public List<Faculty_Payments__mdt> facultyPaymentsMetadataType;
    public Date today;
    
    public VerifyCompensationBatchManual(List<Id> courseOfferingIds) {
        this.courseOfferingIds = courseOfferingIds;
    }
    
    //Runs for Course Offering RT only
    global Database.QueryLocator start(Database.BatchableContext bc) {
        courseOfferingRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Offering').getRecordTypeId();

        facultyPaymentsMetadataType = [
            SELECT Id, DeveloperName, Course_Type__c, Credits__c, Faculty_Type__c, Fee_Type__c, Flat_Fee__c, Level__c, Lower_Range_Enrollment__c, Upper_Range_Enrollment__c
            FROM Faculty_Payments__mdt
        ];
        today = Date.today();

        Custom_Calculation_Date_Offset__c offset = Custom_Calculation_Date_Offset__c.getOrgDefaults();
        String query = 'SELECT Id, Course_Offering_Type__c, Credit_Hours__c, hed__Course__r.Level__c, hed__Faculty__r.Faculty_Level__c, hed__Start_Date__c, Compensation__c, Bi_Weekly_Compensation__c, Number_of_Students_Registered__c, Credits_for_CMDT_Reference__c, Payday_Calculation__c, '
        + 'RecordType.Name, Number_of_Bi_Weekly_Payments__c, Bi_weekly_payments_start__c FROM hed__Course_Offering__c WHERE (RecordTypeId = :courseOfferingRecordTypeId) AND Status__c = \'Active\' AND Id IN :courseOfferingIds';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext bc, List<hed__Course_Offering__c> records) {
        Date today = System.today();
        List<hed__Course_Offering__c> courseOfferingsToUpdate = new List<hed__Course_Offering__c>();
        
        for (Integer i = 0; i < records.size(); i++) {
            Integer studentCount = Integer.valueOf(records[i].Number_of_Students_Registered__c);
            for (Faculty_Payments__mdt facultyPayment: facultyPaymentsMetadataType) {
                if ((records[i].Course_Offering_Type__c == facultyPayment.Course_Type__c || 
                     ((records[i].Course_Offering_Type__c == 'Course Offering' || records[i].Course_Offering_Type__c == 'Onsite Instruction' || records[i].Course_Offering_Type__c == 'Independent Study'
                       || records[i].Course_Offering_Type__c == 'Remote Instruction' || records[i].Course_Offering_Type__c == 'Review - Major' || records[i].Course_Offering_Type__c == 'Developer') 
                      && facultyPayment.Course_Type__c == 'General')) 
                    && (String.valueOf(records[i].Credits_for_CMDT_Reference__c) == facultyPayment.Credits__c || records[i].Credits_for_CMDT_Reference__c == '0' && facultyPayment.Credits__c == null) 
                    && (records[i].hed__Faculty__r.Faculty_Level__c == facultyPayment.Faculty_Type__c)
                    && (records[i].hed__Course__r.Level__c == facultyPayment.Level__c  || ((records[i].hed__Course__r.Level__c == 'Lower' || records[i].hed__Course__r.Level__c == 'Upper') && facultyPayment.Level__c == 'Undergrad'))
                    && studentCount >= facultyPayment.Lower_Range_Enrollment__c
                    && studentCount <= facultyPayment.Upper_Range_Enrollment__c) {
                        Double standardPaymentAmount;
                        if (facultyPayment.Fee_Type__c == 'Per') {
                            standardPaymentAmount = studentCount * Double.valueOf(facultyPayment.Flat_Fee__c);
                        }
                        if (facultyPayment.Fee_Type__c == 'Flat') {
                            standardPaymentAmount = Double.valueOf(facultyPayment.Flat_Fee__c);
                        }
                        records[i].Compensation__c = standardPaymentAmount;
                        courseOfferingsToUpdate.add(records[i]);
                    }
            }
        }

        Database.update(courseOfferingsToUpdate);
        String query = 'SELECT Id, Course_Offering_Type__c, Credit_Hours__c, hed__Course__r.Level__c, hed__Faculty__r.Faculty_Level__c, hed__Start_Date__c, Compensation__c, Bi_Weekly_Compensation__c, Number_of_Students_Registered__c, Credits_for_CMDT_Reference__c, Payday_Calculation__c, '
        + 'RecordType.Name, Number_of_Bi_Weekly_Payments__c, Bi_weekly_payments_start__c FROM hed__Course_Offering__c WHERE Id IN :courseOfferingsToUpdate';
        List<hed__Course_Offering__c> updatedCourseOfferings = Database.query(query);
        
        Map<Id, Double> courseOfferingPaidAmountMap = new Map<Id, Double>();
        Map<Id, Integer> courseOfferingFuturePaymentsCountMap = new Map<Id, Integer>();
        Map<Id, List<Payment__c>> courseOfferingPaymentsMap = new Map<Id, List<Payment__c>>();
        AggregateResult[] scheduledPaymentsWithCount = [
            SELECT Course_Offering__c, COUNT(Id)
            FROM Payment__c
            WHERE Course_Offering__c IN :updatedCourseOfferings AND Payment_Date__c >= :today
			GROUP BY Course_Offering__c
        ];
        
        AggregateResult[] completedPaymentsWithTotals = [
            SELECT Course_Offering__c, SUM(Payment_Amount__c) 
            FROM Payment__c
            WHERE Course_Offering__c IN :updatedCourseOfferings AND Payment_Date__c < :today
			GROUP BY Course_Offering__c
        ];
        
        List<Payment__c> allPayments = [
            SELECT Id, Payment_Amount__c, Course_Offering__c, Payment_Date__c
            FROM Payment__c
            WHERE Course_Offering__c IN :updatedCourseOfferings
        ];
        
        for (AggregateResult ar : scheduledPaymentsWithCount) {
            courseOfferingFuturePaymentsCountMap.put((Id)ar.get('Course_Offering__c'), Integer.valueOf(ar.get('expr0')));
        }
        
        for (AggregateResult ar : completedPaymentsWithTotals) {
            courseOfferingPaidAmountMap.put((Id)ar.get('Course_Offering__c'), (Double)ar.get('expr0'));
        }
        
        for (Payment__c payment : allPayments) {
            for (hed__Course_Offering__c courseOffering : updatedCourseOfferings) {
                if (courseOffering.Id == payment.Course_Offering__c) {
                    List<Payment__c> relatedPayments = courseOfferingPaymentsMap.get(courseOffering.Id);
                    if (relatedPayments == null) {
                        relatedPayments = new List<Payment__c>();
                    }
                    relatedPayments.add(payment);
                    courseOfferingPaymentsMap.put(courseOffering.Id, relatedPayments);
                }
            }
        }
        
        List<Payment__c> paymentsToUpdate = new List<Payment__c>();
        List<Payment__c> paymentsToInsert = new List<Payment__c>();
        List<Payment__c> paymentsToDelete = new List<Payment__c>();
        for (Integer i = 0; i < updatedCourseOfferings.size(); i++) {
            Id recordTypeId = updatedCourseOfferings[i].recordTypeId; 
            Double paidAmount = courseOfferingPaidAmountMap.get(updatedCourseOfferings[i].Id);
            Integer futureCount = courseOfferingFuturePaymentsCountMap.get(updatedCourseOfferings[i].Id);

            if (paidAmount != null && futureCount != null) {
                Double remainingPaymentAmount = (updatedCourseOfferings[i].Compensation__c - paidAmount) / futureCount;
                for (Id courseOfferingId : courseOfferingPaymentsMap.keySet()) {
                    for (Payment__c relatedPayment : courseOfferingPaymentsMap.get(courseOfferingId)) {
                        if (relatedPayment.Payment_Date__c >= today) {
                            relatedPayment.Payment_Amount__c = remainingPaymentAmount;
                            paymentsToUpdate.add(relatedPayment);
                        }
                    }
                }
            } else {
                //Delete old payments and create new ones
                List<Payment__c> payments = courseOfferingPaymentsMap.get(updatedCourseOfferings[i].Id);
                if (payments != null) {
                    for (Payment__c relatedPayment : payments) {
                        paymentsToDelete.add(relatedPayment);
                    }
                }
                for (Integer b = 0; b < updatedCourseOfferings[i].Number_of_Bi_Weekly_Payments__c; b++) {
                    Payment__c newPayment = new Payment__c();
                    newPayment.Course_Offering__c = updatedCourseOfferings[i].Id;
                    newPayment.Payment_Date__c = updatedCourseOfferings[i].Payday_Calculation__c.addDays(b * 14);
                    newPayment.Payment_Amount__c = updatedCourseOfferings[i].Bi_Weekly_Compensation__c;
                    newPayment.Pay_To__c = updatedCourseOfferings[i].hed__Faculty__c;
                    
                    paymentsToInsert.add(newPayment);
                }
            }
        }

        Database.insert(paymentsToInsert);
        Database.delete(paymentsToDelete);
        Database.update(paymentsToUpdate);

        //Reset for next iteration
        courseOfferingsToUpdate = new List<hed__Course_Offering__c>();
        paymentsToInsert = new List<Payment__c>();
        paymentsToDelete = new List<Payment__c>();
        paymentsToUpdate = new List<Payment__c>();
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}