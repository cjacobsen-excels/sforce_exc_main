@isTest
global class CV_Report_ControllerTest {
     @IsTest(SeeAllData=true) 
    global static void testgetreport () {
         
        List<CV_Report_Controller.ReportWrapper> fcmb = CV_Report_Controller.getReport('LAST_YEAR');
        System.assert(![SELECT Id,FileType,CreatedDate,SharingPrivacy,ContentAssetId, ParentId, OwnerId,Owner.Name,SharingOption, Title 
             FROM contentDocument ].isEmpty());
    }  
}