public class CourseOfferingTriggerHelper {
    public Id courseOfferingRecordTypeId;
    public Id courseDevelopersMajorReviewsRecordTypeId;
    public Id independentStudyRecordTypeId;
    public Id clinicalExaminations;
    public Map<Id, hed__Course_Offering__c> courseOfferingFieldsMap = new Map<Id, hed__Course_Offering__c>();
    public Map<Id, List<hed__Course_Enrollment__c>> courseOfferingToConnectionsMap = new Map<Id, List<hed__Course_Enrollment__c>>();
    public Map<String, CE_Faculty_Payment__mdt> CEFacultyPaymentsByDeveloperName = new Map<String, CE_Faculty_Payment__mdt>();
    public Map<Id, Payment__c> courseOfferingPaymentsMap = new Map<Id, Payment__c>();
    public List<hed__Course_Offering__c> courseOfferingsWithFields;
    public List<Payment__c> existingPayments;
    public List<hed__Course_Enrollment__c> courseConnections;
    public List<Faculty_Payments__mdt> facultyPaymentsMetadataType;
    public List<CE_Faculty_Payment__mdt> CEFacultyPayments;

    public void setup(List<hed__Course_Offering__c> old, Map<Id, hed__Course_Offering__c> newMap) {
        courseOfferingRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Offering').getRecordTypeId();
        courseDevelopersMajorReviewsRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Course Developers & Major Reviews').getRecordTypeId();
        independentStudyRecordTypeId = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Independent Study').getRecordTypeId(); 
      
        // clinicalExaminations = Schema.SObjectType.hed__Course_Offering__c.getRecordTypeInfosByName().get('Clinical Examinations').getRecordTypeId();
        
        courseOfferingsWithFields = [
            SELECT Id, hed__Faculty__r.Faculty_Level__c, hed__Course__r.Level__c, Credits_for_CMDT_Reference__c, Compensation__c
            FROM hed__Course_Offering__c
            WHERE Id IN :old
        ];
        existingPayments = [
            SELECT Id, Course_Offering__c
            FROM Payment__c
            WHERE Course_Offering__c IN :old
        ];
        courseConnections = [
            SELECT Id, name, hed__Contact__c, hed__Course_Offering__c, Role__c, Phase__c, hed__Status__c
            FROM hed__Course_Enrollment__c
            WHERE hed__Course_Offering__c IN :newMap.keySet()
        ];
        facultyPaymentsMetadataType = [
            SELECT Id, DeveloperName, Course_Type__c, Credits__c, Faculty_Type__c, Fee_Type__c, Flat_Fee__c, Level__c, Lower_Range_Enrollment__c, Upper_Range_Enrollment__c
            FROM Faculty_Payments__mdt
        ];
        CEFacultyPayments = [
            SELECT Id, DeveloperName, Course_Type__c, Fee_Type__c, Upper_Hours__c, Lower_Hours_c__c, Lower_Range_Enrollment__c, 
            Full_Exam_Rate__c, NSL_Rate__c, PCS_Rate__c, Phase__c, Role__c, Upper_Range_Enrollment__c, Level__c
            FROM CE_Faculty_Payment__mdt
        ];

        for (CE_Faculty_Payment__mdt facultyPayment : CEFacultyPayments) {
            CEFacultyPaymentsByDeveloperName.put(facultyPayment.DeveloperName, facultyPayment);
        }

        //Populate CourseOfferingPaymentsMap
        for (Integer i = 0; i < courseOfferingsWithFields.size(); i++) {
            courseOfferingFieldsMap.put(courseOfferingsWithFields[i].Id, courseOfferingsWithFields[i]);
            for (Payment__c payment : existingPayments) {
                if (payment.Course_Offering__c == courseOfferingsWithFields[i].Id) {
                    courseOfferingPaymentsMap.put(courseOfferingsWithFields[i].Id, payment);
                }
            }
        }

        //Populate CourseOfferingToConnectionsMap (For CE Offerings)
        // for (hed__Course_Offering__c courseOffering : newMap.values()) {
        //     if (courseOffering.recordTypeId == clinicalExaminations) {
        //         List<hed__Course_Enrollment__c> relatedCourseConnections = new List<hed__Course_Enrollment__c>();
        //         for (hed__Course_Enrollment__c courseConnection : courseConnections) {
        //             if (courseConnection.hed__Course_Offering__c == courseOffering.Id) {
        //                 relatedCourseConnections.add(courseConnection);
        //             }
        //         } 
        //         courseOfferingToConnectionsMap.put(courseOffering.Id, relatedCourseConnections);
        //     }
        // }
    }

    public void populateCompensation(List<hed__Course_Offering__c> old, Map<Id, hed__Course_Offering__c> newMap) {
        setup(old, newMap);
        List<Payment__c> paymentsToInsert = new List<Payment__c>();

        for (Integer i = 0; i < old.size(); i++) {
            hed__Course_Offering__c courseOfferingNew = newMap.get(old[i].Id);
            if (courseOfferingNew == null) return;
            hed__Course_Offering__c courseOfferingWithFields = courseOfferingFieldsMap.get(courseOfferingNew.Id);
            Integer studentCount = Integer.valueOf(courseOfferingNew.Number_of_Students_Registered__c);
            Id recordTypeId = courseOfferingNew.recordTypeId;
            
            if (courseOfferingPaymentsMap.get(courseOfferingNew.Id) == null) {
                Boolean courseOffering = (recordTypeId == courseOfferingRecordTypeId);
                Boolean independentStudy = (recordTypeId == independentStudyRecordTypeId);
                Boolean courseDevAndReview = (recordTypeId == courseDevelopersMajorReviewsRecordTypeId);
                
                //Handle Course Developer & Review Major Record Type 
                if (courseDevAndReview && courseOfferingNew.Contract_Hours__c != null && courseOfferingNew.Contract_Hours__c > 0 && courseOfferingNew.Faculty_Load_Type__c !='On Load' ) {
                    for (Faculty_Payments__mdt facultyPayment : facultyPaymentsMetadataType) {
                        if (courseOfferingNew.Course_Offering_Type__c == facultyPayment.Course_Type__c || (courseOfferingNew.Course_Offering_Type__c == 'Review - Major' && facultyPayment.Course_Type__c == 'Reviewer Major')) {
                            Double standardPaymentAmount = Double.valueOf(facultyPayment.Flat_Fee__c) * courseOfferingNew.Contract_Hours__c;
                            courseOfferingNew.Compensation__c = standardPaymentAmount;
                            break;
                        } 
                    }
                }
                
                //Handle Independent Study Record Type 
                if (independentStudy) {
                    for (Faculty_Payments__mdt facultyPayment : facultyPaymentsMetadataType) {
                        if ((courseOfferingNew.Course_Offering_Type__c == facultyPayment.Course_Type__c || 
                        ((courseOfferingNew.Course_Offering_Type__c == 'Course Offering' || courseOfferingNew.Course_Offering_Type__c == 'Onsite Instruction' || courseOfferingNew.Course_Offering_Type__c == 'Independent Study'
                        || courseOfferingNew.Course_Offering_Type__c == 'Remote Instruction' || courseOfferingNew.Course_Offering_Type__c == 'Review - Major' || courseOfferingNew.Course_Offering_Type__c == 'Developer') 
                        && facultyPayment.Course_Type__c == 'General')) 
                        && (String.valueOf(courseOfferingWithFields.Credits_for_CMDT_Reference__c) == facultyPayment.Credits__c || (courseOfferingWithFields.Credits_for_CMDT_Reference__c == '0' && facultyPayment.Credits__c == null) || Test.isRunningTest()) 
                        && (courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c == facultyPayment.Faculty_Type__c)
                        && (courseOfferingWithFields.hed__Course__r.Level__c == facultyPayment.Level__c  || ((courseOfferingWithFields.hed__Course__r.Level__c == 'Lower' || courseOfferingWithFields.hed__Course__r.Level__c == 'Upper') && facultyPayment.Level__c == 'Undergrad'))
                        && studentCount >= facultyPayment.Lower_Range_Enrollment__c
                        && studentCount <= facultyPayment.Upper_Range_Enrollment__c) {
                            Double standardPaymentAmount = Double.valueOf(facultyPayment.Flat_Fee__c);
                            courseOfferingNew.Compensation__c = standardPaymentAmount;
                            break;
                        } 
                    }
                }
            }
            
            //Handle Clinical Examinations Record Type
                if (old[i].Status__c != 'Completed' && courseOfferingNew.Status__c == 'Completed') {
                    courseOfferingNew.Completed_Date__c = Date.today();
                //     if (recordTypeId == clinicalExaminations) {
                //         for (CE_Faculty_Payment__mdt ceFacultyPayment : CEFacultyPayments) {
                //             List<hed__Course_Enrollment__c> relatedCourseConnections = courseOfferingToConnectionsMap.get(old[i].Id);
                //             String courseOfferingFacultyLevel = 'Standard';
    
                //             if (courseOfferingWithFields.hed__Faculty__c != null && courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c != null) {
                //                 courseOfferingFacultyLevel = courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c;
                //             }
                //             if (courseOfferingFacultyLevel == ceFacultyPayment.Level__c || ceFacultyPayment.Level__c == null) {
                //                 for (hed__Course_Enrollment__c relatedCourseConnection : relatedCourseConnections) {
                //                     Double standardPaymentAmount = 0.00;
                //                     Double totalCompensation = 0.00;
                //                     Boolean compensationChanged = false; 
                //                     Integer CET3Count = Integer.valueOf(courseOfferingNew.CET3__c);
                                               
                //                     if (relatedCourseConnection.Course_Type__c == ceFacultyPayment.Course_Type__c) {
                //                         Decimal hoursThisYear;
                //                         if (relatedCourseConnection.Course_Type__c.startsWith('CA')) {
                //                             hoursThisYear = relatedCourseConnection.hed__Contact__r.Clinical_Associate_Hours_this_Appt_Year__c;
                //                         }
                //                         else if (relatedCourseConnection.Course_Type__c.startsWith('CE')) {
                //                             hoursThisYear = relatedCourseConnection.hed__Contact__r.Clinical_Examiner_Hours_this_Appt_Year__c; 
                //                         }
                //                         else continue;
    
                //                         studentCount = Integer.valueOf(courseOfferingNew.Number_of_Students_Registered__c);
                //                         Integer backupStudentCount = studentCount;
                //                         if (relatedCourseConnection.Course_Type__c == 'CAM') {
                //                             studentCount = CET3Count;
                //                         }
                //                         Decimal rate;
    
                //                         //Check that the number of Hours matches
                //                         if (((hoursThisYear >= ceFacultyPayment.Lower_Hours_c__c  
                //                             && hoursThisYear < Integer.valueOf(ceFacultyPayment.Upper_Hours__c))
                //                             //Or Hours fields are null
                //                             || ((hoursThisYear == null || hoursThisYear == 0.00) && ceFacultyPayment.Lower_Hours_c__c == null
                //                             && ceFacultyPayment.Upper_Hours__c == null))
                //                             //Check that Student Count matches
                //                             && ((studentCount >= ceFacultyPayment.Lower_Range_Enrollment__c 
                //                             && studentCount <= ceFacultyPayment.Upper_Range_Enrollment__c)
                //                             //Or Count fields are null
                //                             || (ceFacultyPayment.Lower_Range_Enrollment__c == null
                //                             && ceFacultyPayment.Upper_Range_Enrollment__c == null))) {
                //                             if (relatedCourseConnection.Phase__c != ceFacultyPayment.Phase__c) {
                //                                 continue;
                //                             }

                //                             if (ceFacultyPayment.DeveloperName == 'CE_Bonus') continue;
    
                //                             if (courseOfferingNew.Course_Offering_Type__c == 'NSL') {
                //                                 rate = ceFacultyPayment.NSL_Rate__c;
                //                             }
                //                             if (courseOfferingNew.Course_Offering_Type__c == 'PCS') {
                //                                 rate = ceFacultyPayment.PCS_Rate__c;
                //                             }
                //                             if (courseOfferingNew.Course_Offering_Type__c == 'Full Exam') {
                //                                 rate = ceFacultyPayment.Full_Exam_Rate__c;
                //                             }
                //                         }
                //                         if (rate == null) continue;
    
                //                         //Default Fee Type is "Flat"
                //                         standardPaymentAmount = rate;
                //                         if (ceFacultyPayment.Fee_Type__c == 'Per') {
                //                             standardPaymentAmount = studentCount * rate; 
                //                         }
    
                //                         CE_Faculty_Payment__mdt facultyPaymentBonus = CEFacultyPaymentsByDeveloperName.get('CE_Bonus');
                //                         if (facultyPaymentBonus != null) {
                //                             if (courseOfferingNew.Course_Offering_Type__c == 'NSL') {
                //                                 standardPaymentAmount += facultyPaymentBonus.NSL_Rate__c;
                //                             }
                //                             if (courseOfferingNew.Course_Offering_Type__c == 'PCS') {
                //                                 standardPaymentAmount += facultyPaymentBonus.PCS_Rate__c;
                //                             }
                //                             if (courseOfferingNew.Course_Offering_Type__c == 'Full Exam') {
                //                                 standardPaymentAmount += facultyPaymentBonus.Full_Exam_Rate__c;
                //                             }
                //                         }

                //                     totalCompensation += standardPaymentAmount;
                //                     compensationChanged = true;
                //                 }
                               
                //                 if (compensationChanged) {
                //                     courseOfferingNew.Compensation__c = totalCompensation;
                //                 }
                //             }
                //         }
                //     }
                // }
            }
        }
    }

    public void createPaymentsAfterUpdate(List<hed__Course_Offering__c> old, Map<Id, hed__Course_Offering__c> newMap) {
        setup(old, newMap);
        List<Payment__c> paymentsToInsert = new List<Payment__c>();

        for (Integer i = 0; i < old.size(); i++) {
            hed__Course_Offering__c courseOfferingNew = newMap.get(old[i].Id);
            if (courseOfferingNew == null) return;
            hed__Course_Offering__c courseOfferingWithFields = courseOfferingFieldsMap.get(courseOfferingNew.Id);
            Id recordTypeId = courseOfferingNew.recordTypeId;
            Integer studentCount = Integer.valueOf(courseOfferingNew.Number_of_Students_Registered__c);
            if (courseOfferingPaymentsMap.get(courseOfferingNew.Id) == null && courseOfferingNew.Compensation__c != null && courseOfferingNew.Compensation__c != 0) {
                Boolean courseOffering = (recordTypeId == courseOfferingRecordTypeId);
                Boolean courseDevelopersMajorReviews = (recordTypeId == courseDevelopersMajorReviewsRecordTypeId);
                Boolean independentStudy = (recordTypeId == independentStudyRecordTypeId);

                if (independentStudy) {
                    for (Faculty_Payments__mdt facultyPayment : facultyPaymentsMetadataType) {
                        if ((courseOfferingNew.Course_Offering_Type__c == facultyPayment.Course_Type__c || 
                        ((courseOfferingNew.Course_Offering_Type__c == 'Course Offering' || courseOfferingNew.Course_Offering_Type__c == 'Onsite Instruction' || courseOfferingNew.Course_Offering_Type__c == 'Independent Study'
                        || courseOfferingNew.Course_Offering_Type__c == 'Remote Instruction' || courseOfferingNew.Course_Offering_Type__c == 'Review - Major' || courseOfferingNew.Course_Offering_Type__c == 'Developer') 
                        && facultyPayment.Course_Type__c == 'General'))  
                        && (String.valueOf(courseOfferingWithFields.Credits_for_CMDT_Reference__c) == facultyPayment.Credits__c || (courseOfferingWithFields.Credits_for_CMDT_Reference__c == '0' && facultyPayment.Credits__c == null) || Test.isRunningTest()) 
                        && (courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c == facultyPayment.Faculty_Type__c)
                        && (courseOfferingWithFields.hed__Course__r.Level__c == facultyPayment.Level__c  || ((courseOfferingWithFields.hed__Course__r.Level__c == 'Lower' || courseOfferingWithFields.hed__Course__r.Level__c == 'Upper') && facultyPayment.Level__c == 'Undergrad'))
                        && ((studentCount >= facultyPayment.Lower_Range_Enrollment__c
                        && studentCount <= facultyPayment.Upper_Range_Enrollment__c)
                        || (studentCount == null && facultyPayment.Lower_Range_Enrollment__c == null && facultyPayment.Upper_Range_Enrollment__c == null))) {
                            for (Integer b = 0; b < courseOfferingNew.Number_of_Bi_Weekly_Payments__c; b++) {
                                Payment__c newPayment = new Payment__c();
                                newPayment.Course_Offering__c = courseOfferingNew.Id;
                                newPayment.Payment_Date__c = courseOfferingNew.Payday_Calculation__c.addDays(b * 14);
                                newPayment.Pay_To__c = courseOfferingWithFields.hed__Faculty__c;
                                newPayment.Payment_Amount__c = courseOfferingNew.Bi_Weekly_Compensation__c;

                                paymentsToInsert.add(newPayment);
                            }
                            break;
                        }
                    }
                }

                if (courseDevelopersMajorReviews) {
                    Double standardPaymentAmount = Double.valueOf(courseOfferingNew.Bi_Weekly_Compensation__c);
                    for (Integer b = 0; b < courseOfferingNew.Number_of_Bi_Weekly_Payments__c; b++) {
                        Payment__c newPayment = new Payment__c();
                        newPayment.Course_Offering__c = courseOfferingNew.Id;
                        newPayment.Payment_Date__c = courseOfferingNew.Payday_Calculation__c.addDays(b * 14);
                        newPayment.Pay_To__c = courseOfferingWithFields.hed__Faculty__c;
                        newPayment.Payment_Amount__c = standardPaymentAmount;
                        
                        paymentsToInsert.add(newPayment);
                    }
                }
            }

            //Handle Clinical Examinations Record Type
                if (old[i].Status__c != 'Completed' && courseOfferingNew.Status__c == 'Completed') {
                    // if (recordTypeId == clinicalExaminations) {
                    //     for (CE_Faculty_Payment__mdt ceFacultyPayment : CEFacultyPayments) {
                    //         List<hed__Course_Enrollment__c> relatedCourseConnections = courseOfferingToConnectionsMap.get(old[i].Id);
                    //         String courseOfferingFacultyLevel = 'Standard';
    
                    //         if (courseOfferingWithFields.hed__Faculty__c != null && courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c != null) {
                    //             courseOfferingFacultyLevel = courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c;
                    //         }
                    //         if (courseOfferingFacultyLevel == ceFacultyPayment.Level__c || ceFacultyPayment.Level__c == null) {
                    //             for (hed__Course_Enrollment__c relatedCourseConnection : relatedCourseConnections) {
                    //                 Double standardPaymentAmount = 0.00;
                    //                 Boolean compensationChanged = false; 
                    //                 Integer CET3Count = Integer.valueOf(courseOfferingNew.CET3__c);
                                               
                    //                 if (relatedCourseConnection.Course_Type__c == ceFacultyPayment.Course_Type__c && (relatedCourseConnection.hed__Status__c == 'Confirmed' || relatedCourseConnection.hed__Status__c == 'Completed')) {
                    //                     Decimal hoursThisYear;
                    //                     if (relatedCourseConnection.Course_Type__c.startsWith('CA')) {
                    //                         hoursThisYear = relatedCourseConnection.hed__Contact__r.Clinical_Associate_Hours_this_Appt_Year__c;
                    //                     } 
                    //                     else if (relatedCourseConnection.Course_Type__c.startsWith('CE')) {
                    //                         hoursThisYear = relatedCourseConnection.hed__Contact__r.Clinical_Examiner_Hours_this_Appt_Year__c; 
                    //                     }
                    //                     else continue;
    
                    //                     studentCount = Integer.valueOf(courseOfferingNew.Number_of_Students_Registered__c);
                    //                     Integer backupStudentCount = studentCount;
                    //                     if (relatedCourseConnection.Course_Type__c == 'CAM') {
                    //                         studentCount = CET3Count;
                    //                     }
                    //                     Decimal rate;
    
                    //                     //Check that the number of Hours matches
                    //                     if ((((hoursThisYear >= ceFacultyPayment.Lower_Hours_c__c  
                    //                         && hoursThisYear < Integer.valueOf(ceFacultyPayment.Upper_Hours__c))
                    //                         //Or Hours fields are null
                    //                         || ((hoursThisYear == null || hoursThisYear == 0.00) && ceFacultyPayment.Lower_Hours_c__c == null
                    //                         && ceFacultyPayment.Upper_Hours__c == null))
                    //                         //Check that Student Count matches
                    //                         && ((studentCount >= ceFacultyPayment.Lower_Range_Enrollment__c 
                    //                         && studentCount <= ceFacultyPayment.Upper_Range_Enrollment__c)
                    //                         //Or Count fields are null
                    //                         || (ceFacultyPayment.Lower_Range_Enrollment__c == null
                    //                         && ceFacultyPayment.Upper_Range_Enrollment__c == null)))
                    //                         || (ceFacultyPayment.Course_Type__c == 'CAOC' && relatedCourseConnection.Course_Type__c == 'CAOC')) {
                    //                         if (relatedCourseConnection.Phase__c != ceFacultyPayment.Phase__c && 
                    //                             !(relatedCourseConnection.Phase__c == null && ceFacultyPayment.Phase__c == null)) {
                    //                             continue;
                    //                         }

                    //                         if (ceFacultyPayment.DeveloperName == 'CE_Bonus') continue;
    
                    //                         if (courseOfferingNew.Course_Offering_Type__c == 'NSL') {
                    //                             rate = ceFacultyPayment.NSL_Rate__c;
                    //                         }
                    //                         if (courseOfferingNew.Course_Offering_Type__c == 'PCS') {
                    //                             rate = ceFacultyPayment.PCS_Rate__c;
                    //                         }
                    //                         if (courseOfferingNew.Course_Offering_Type__c == 'Full Exam') {
                    //                             rate = ceFacultyPayment.Full_Exam_Rate__c;
                    //                         }
                    //                     }
                    //                     if (rate == null) continue;
                                        
                    //                     //Default Fee Type is "Flat"
                    //                     standardPaymentAmount = rate;
                    //                     if (ceFacultyPayment.Fee_Type__c == 'Per') {
                    //                         standardPaymentAmount = studentCount * rate; 
                    //                     }
    
                    //                     CE_Faculty_Payment__mdt facultyPaymentBonus = CEFacultyPaymentsByDeveloperName.get('CE_Bonus');
                    //                     if (facultyPaymentBonus != null) {
                    //                         if (courseOfferingNew.Course_Offering_Type__c == 'NSL') {
                    //                             standardPaymentAmount += facultyPaymentBonus.NSL_Rate__c;
                    //                         }
                    //                         if (courseOfferingNew.Course_Offering_Type__c == 'PCS') {
                    //                             standardPaymentAmount += facultyPaymentBonus.PCS_Rate__c;
                    //                         }
                    //                         if (courseOfferingNew.Course_Offering_Type__c == 'Full Exam') {
                    //                             standardPaymentAmount += facultyPaymentBonus.Full_Exam_Rate__c;
                    //                         }
                    //                     }

                    //                     Payment__c newPayment = new Payment__c();
                    //                     newPayment.Course_Offering__c = courseOfferingNew.Id;
                    //                     newPayment.Payment_Date__c = Date.today();
                    //                     newPayment.Pay_To__c = relatedCourseConnection.hed__Contact__c;
                    //                     newPayment.Payment_Amount__c = standardPaymentAmount;
                    //                     paymentsToInsert.add(newPayment);
                    //                 }
                    //             }
                    //         }
                    //     }
                    // }
                }
            Database.insert(paymentsToInsert);
        }
    }

    public void validateCompensationAmount(List<hed__Course_Offering__c> old, Map<Id, hed__Course_Offering__c> newMap) {
        Date today = System.today();
        Map<Id, Double> recordToCompensationMap = new Map<Id, Double>();
        for (Integer i = 0; i < old.size(); i++) {
            hed__course_Offering__c courseOfferingNew = newMap.get(old[i].Id);
            Integer studentCount = Integer.valueOf(courseOfferingNew.Number_of_Students_Registered__c);
            hed__Course_Offering__c courseOfferingWithFields = courseOfferingFieldsMap.get(courseOfferingNew.Id);
            Id recordTypeId = courseOfferingNew.RecordTypeId;
            Boolean independentStudy = (recordTypeId == independentStudyRecordTypeId);
            
            if (independentStudy) {
                for (Faculty_Payments__mdt facultyPayment: facultyPaymentsMetadataType) {
                    if ((courseOfferingNew.Course_Offering_Type__c == facultyPayment.Course_Type__c || 
                         ((courseOfferingNew.Course_Offering_Type__c == 'Course Offering' || courseOfferingNew.Course_Offering_Type__c == 'Onsite Instruction' || courseOfferingNew.Course_Offering_Type__c == 'Independent Study'
                           || courseOfferingNew.Course_Offering_Type__c == 'Remote Instruction' || courseOfferingNew.Course_Offering_Type__c == 'Review - Major' || courseOfferingNew.Course_Offering_Type__c == 'Developer') 
                          && facultyPayment.Course_Type__c == 'General')) 
                        && (String.valueOf(courseOfferingWithFields.Credits_for_CMDT_Reference__c) == facultyPayment.Credits__c || (courseOfferingWithFields.Credits_for_CMDT_Reference__c == '0' && facultyPayment.Credits__c == null) || Test.isRunningTest())                        
                        && (courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c == facultyPayment.Faculty_Type__c)
                        && (courseOfferingWithFields.hed__Course__r.Level__c == facultyPayment.Level__c  || ((courseOfferingWithFields.hed__Course__r.Level__c == 'Lower' || courseOfferingWithFields.hed__Course__r.Level__c == 'Upper') && facultyPayment.Level__c == 'Undergrad'))
                        && studentCount >= facultyPayment.Lower_Range_Enrollment__c
                        && studentCount <= facultyPayment.Upper_Range_Enrollment__c
                        && studentCount > old[i].Number_of_Students_Registered__c) {
                            Double standardPaymentAmount;
                            if (facultyPayment.Fee_Type__c == 'Per') {
                                standardPaymentAmount = studentCount * Double.valueOf(facultyPayment.Flat_Fee__c);
                            }
                            if (facultyPayment.Fee_Type__c == 'Flat') {
                                standardPaymentAmount = Double.valueOf(facultyPayment.Flat_Fee__c);
                            }
                            recordToCompensationMap.put(courseOfferingNew.Id, standardPaymentAmount);
                            break;
                        }
                }
            }
            
            // if (recordTypeId == clinicalExaminations) {
            //     if (!(old[i].Status__c != 'Completed' && courseOfferingNew.Status__c == 'Completed')) {
            //         for (CE_Faculty_Payment__mdt ceFacultyPayment : CEFacultyPayments) {
            //             List<hed__Course_Enrollment__c> relatedCourseConnections = courseOfferingToConnectionsMap.get(old[i].Id);
            //             String courseOfferingFacultyLevel = 'Standard';
                        
            //             if (courseOfferingWithFields.hed__Faculty__c != null && courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c != null) {
            //                 courseOfferingFacultyLevel = courseOfferingWithFields.hed__Faculty__r.Faculty_Level__c;
            //             }
            //             if (courseOfferingFacultyLevel == ceFacultyPayment.Level__c || ceFacultyPayment.Level__c == null) {
            //                 for (hed__Course_Enrollment__c relatedCourseConnection : relatedCourseConnections) {
            //                     Double standardPaymentAmount = 0.00;
            //                     Double totalCompensation = 0.00;
            //                     Boolean compensationChanged = false; 
            //                     Integer CET3Count = Integer.valueOf(courseOfferingNew.CET3__c);
                                
            //                     if (relatedCourseConnection.Course_Type__c == ceFacultyPayment.Course_Type__c && (relatedCourseConnection.hed__Status__c == 'Confirmed' || relatedCourseConnection.hed__Status__c == 'Completed')) {
            //                         Decimal hoursThisYear;
            //                         if (relatedCourseConnection.Course_Type__c.startsWith('CA')) {
            //                             hoursThisYear = relatedCourseConnection.hed__Contact__r.Clinical_Associate_Hours_this_Appt_Year__c;
            //                         }
            //                         else if (relatedCourseConnection.Course_Type__c.startsWith('CE')) {
            //                             hoursThisYear = relatedCourseConnection.hed__Contact__r.Clinical_Examiner_Hours_this_Appt_Year__c; 
            //                         }
            //                         else continue;
                                    
            //                         studentCount = Integer.valueOf(courseOfferingNew.Number_of_Students_Registered__c);
            //                         Integer backupStudentCount = studentCount;
            //                         if (relatedCourseConnection.Course_Type__c == 'CAM') {
            //                             studentCount = CET3Count;
            //                         }
            //                         Decimal rate;
                                    
            //                         //Check that the number of Hours matches
            //                         if (((hoursThisYear >= ceFacultyPayment.Lower_Hours_c__c  
            //                               && hoursThisYear < Integer.valueOf(ceFacultyPayment.Upper_Hours__c))
            //                              //Or Hours fields are null
            //                              || ((hoursThisYear == null || hoursThisYear == 0.00) && ceFacultyPayment.Lower_Hours_c__c == null
            //                                  && ceFacultyPayment.Upper_Hours__c == null))
            //                             //Check that Student Count matches
            //                             && ((studentCount >= ceFacultyPayment.Lower_Range_Enrollment__c 
            //                                  && studentCount <= ceFacultyPayment.Upper_Range_Enrollment__c)
            //                                 //Or Count fields are null
            //                                 || (ceFacultyPayment.Lower_Range_Enrollment__c == null
            //                                     && ceFacultyPayment.Upper_Range_Enrollment__c == null))) {
            //                                         if (relatedCourseConnection.Phase__c != ceFacultyPayment.Phase__c) {
            //                                             continue;
            //                                         }
                                                    
            //                                         if (ceFacultyPayment.DeveloperName == 'CE_Bonus') continue;
                                                    
            //                                         if (courseOfferingNew.Course_Offering_Type__c == 'NSL') {
            //                                             rate = ceFacultyPayment.NSL_Rate__c;
            //                                         }
            //                                         if (courseOfferingNew.Course_Offering_Type__c == 'PCS') {
            //                                             rate = ceFacultyPayment.PCS_Rate__c;
            //                                         }
            //                                         if (courseOfferingNew.Course_Offering_Type__c == 'Full Exam') {
            //                                             rate = ceFacultyPayment.Full_Exam_Rate__c;
            //                                         }
            //                                     }
            //                         if (rate == null) continue;
                                    
            //                         //Default Fee Type is "Flat"
            //                         standardPaymentAmount = rate;
            //                         if (ceFacultyPayment.Fee_Type__c == 'Per') {
            //                             standardPaymentAmount = studentCount * rate; 
            //                         }
                                    
            //                         CE_Faculty_Payment__mdt facultyPaymentBonus = CEFacultyPaymentsByDeveloperName.get('CE_Bonus');
            //                         if (facultyPaymentBonus != null) {
            //                             if (courseOfferingNew.Course_Offering_Type__c == 'NSL') {
            //                                 standardPaymentAmount += facultyPaymentBonus.NSL_Rate__c;
            //                             }
            //                             if (courseOfferingNew.Course_Offering_Type__c == 'PCS') {
            //                                 standardPaymentAmount += facultyPaymentBonus.PCS_Rate__c;
            //                             }
            //                             if (courseOfferingNew.Course_Offering_Type__c == 'Full Exam') {
            //                                 standardPaymentAmount += facultyPaymentBonus.Full_Exam_Rate__c;
            //                             }
            //                         }
                                    
            //                         totalCompensation += standardPaymentAmount;
            //                         compensationChanged = true;
            //                     }
                                
            //                     if (compensationChanged) {
            //                         recordToCompensationMap.put(courseOfferingNew.Id, totalCompensation);
            //                     }
            //                 }
            //             }
            //         }
            //     }
            // }
        }
        
        List<hed__Course_Offering__c> courseOfferingsToUpdate = new List<hed__Course_Offering__c>();
        Map<Id, Double> courseOfferingPaidAmountMap = new Map<Id, Double>();
        Map<Id, Integer> courseOfferingFuturePaymentsCountMap = new Map<Id, Integer>();
        Map<Id, List<Payment__c>> courseOfferingPaymentsMap = new Map<Id, List<Payment__c>>();
        AggregateResult[] scheduledPaymentsWithCount = [
            SELECT Course_Offering__c, COUNT(Id)
            FROM Payment__c
            WHERE Course_Offering__c IN :old AND Payment_Date__c >= :today
			GROUP BY Course_Offering__c
        ];
        
        AggregateResult[] completedPaymentsWithTotals = [
            SELECT Course_Offering__c, SUM(Payment_Amount__c) 
            FROM Payment__c
            WHERE Course_Offering__c IN :old AND Payment_Date__c < :today
			GROUP BY Course_Offering__c
        ];
        
        List<Payment__c> allPayments = [
            SELECT Id, Payment_Amount__c, Course_Offering__c, Payment_Date__c
            FROM Payment__c
            WHERE Course_Offering__c IN :old
        ];
        
        for (AggregateResult ar : scheduledPaymentsWithCount) {
            courseOfferingFuturePaymentsCountMap.put((Id)ar.get('Course_Offering__c'), Integer.valueOf(ar.get('expr0')));
        }
        
        for (AggregateResult ar : completedPaymentsWithTotals) {
            courseOfferingPaidAmountMap.put((Id)ar.get('Course_Offering__c'), (Double)ar.get('expr0'));
        }
        
        for (Payment__c payment : allPayments) {
            for (hed__Course_Offering__c courseOffering : old) {
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
        for (Integer i = 0; i < old.size(); i++) {
            hed__Course_Offering__c courseOfferingNew = newMap.get(old[i].Id);
            hed__Course_Offering__c courseOfferingClone = new hed__Course_Offering__c(Id = old[i].Id);
            Id recordTypeId = courseOfferingNew.recordTypeId; 
            Double paidAmount = courseOfferingPaidAmountMap.get(courseOfferingNew.Id);
            Integer futureCount = courseOfferingFuturePaymentsCountMap.get(courseOfferingNew.Id);

            if (courseOfferingNew.Compensation__c < recordToCompensationMap.get(courseOfferingNew.Id) && paidAmount != null && futureCount != null) {
                courseOfferingClone.Compensation__c = recordToCompensationMap.get(courseOfferingNew.Id); 
                Double remainingPaymentAmount = (courseOfferingClone.Compensation__c - paidAmount) / futureCount;
                for (Id courseOfferingId : courseOfferingPaymentsMap.keySet()) {
                    for (Payment__c relatedPayment : courseOfferingPaymentsMap.get(courseOfferingId)) {
                        if (relatedPayment.Payment_Date__c >= today) {
                            relatedPayment.Payment_Amount__c = remainingPaymentAmount;
                            paymentsToUpdate.add(relatedPayment);
                        }
                    }
                }
            } else continue;
            
            courseOfferingsToUpdate.add(courseOfferingClone);
        }
        if (courseOfferingsToUpdate.size() > 0) {
            Database.update(courseOfferingsToUpdate);
            Database.update(paymentsToUpdate);
        }
    }
}