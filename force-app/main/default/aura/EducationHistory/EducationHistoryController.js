/**
 * Created by mnahar on 23/06/21.
 */

({
    init: function (cmp, event, helper) {
        cmp.set('v.columns', [
            {label: 'Application Name', fieldName: 'ApplicationName', type: 'text'},
            {label: 'Institution Name', fieldName: 'traa_Institution_Name__c', type: 'text'},
            {label: 'Transcript Status', fieldName: 'Transcript_Status__c', type: 'text'}
        ]);

        helper.getEducationHistory(cmp, event, helper);
    }
});