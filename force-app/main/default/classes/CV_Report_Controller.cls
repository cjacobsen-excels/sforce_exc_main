/** 
 * @author Gourav Sharma
 * @email gourav.sharma@mtxb2b.com
 * @description This class provides method for generating Content Document Data
 * Lightning Web Component resources.
 */
public with sharing class CV_Report_Controller {
 
    /**
    * @author Gourav Sharma
    * @email gourav.sharma@mtxb2b.com
    * @description Reusable method for generating the list of filteredRequests Cv_report_DataTable
    * @return Report Wrapper contents for Wire data feed
    */
 
    @AuraEnabled(cacheable=true)
    public static List<ReportWrapper> getReport(String filter){
        List<String> filterdata = new List<String>();
        if(filter == 'LAST_YEAR'){
        filterdata.add('THIS_YEAR');
        filterdata.add('LAST_YEAR');
        }
        else{
            filterdata.add(filter);
        }
        List<ReportWrapper> items = new List<ReportWrapper>(); 

        // To navigate to the list view record
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String baseRecordURL = baseUrl + '/one/one.app?#/sObject/'; // force rendering in Lightning instead of Classic
        String baseUrlSuffix = '/view'; // Required for Lightning record view
 
        String query =
        'SELECT Id,FileType,CreatedDate,SharingPrivacy,ContentAssetId, ParentId, OwnerId,Owner.Name,SharingOption, Title  ' +
        'FROM contentDocument ' +
        'WHERE (Title Like \'%CV%\' or Title like \'%resume%\')  ' +
        'AND CreatedDate IN '+filterdata+ '  WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC';
     
        
            // Generate record
            for (contentDocument cd : Database.query(query)) {
                    
                    ReportWrapper rw     = new ReportWrapper();
                    rw.id                = cd.Id;
                    rw.fileType          = cd.FileType;
                    rw.createdDate       = cd.CreatedDate;
                    rw.ownerName         = cd.Owner.Name; 
                    rw.url               = baseRecordURL + cd.Id + baseUrlSuffix; 
                    rw.downloadUrl       = baseUrl+'/sfc/servlet.shepherd/document/download/'+cd.Id;
                    rw.btnName           = 'DownLoad';
                    items.add(rw);
            }
        //return table data
        return items;  
    }
 
    /**
    * @author Gourav Sharma
    * @email gourav.sharma@mtxb2b.com
    * @description This is a wrapper class.
    * @return nothing
    */
    public class ReportWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String fileType;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String url; 
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String btnName;
          
    }
}