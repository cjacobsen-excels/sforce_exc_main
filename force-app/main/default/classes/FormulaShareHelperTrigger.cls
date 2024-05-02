public class FormulaShareHelperTrigger  {

	public static void calculate(List<Formula_Share_Custom__c> customSettings, String sObjectApi, Set<Id> updatedRecords){
		Map<String,String> fieldToAccessLevelMap = new Map<String,String>();
		List<String> fieldVal = new List<String>();
		String FieldApi = '';
		for(Formula_Share_Custom__c fsc: customSettings){
			fieldToAccessLevelMap.put(fsc.Formula_Field_API__c,fsc.Share_Level__c);
			fieldVal.add(fsc.Formula_Field_API__c);
			if(FieldApi == ''){
				FieldApi += fsc.Formula_Field_API__c;
			}
			else{
				FieldApi += ',' + fsc.Formula_Field_API__c;
			}
		}
		
		String queryStr = 'SELECT Id';
        if (FieldApi == '') {
            queryStr += ' FROM ' + sObjectApi + ' WHERE Id IN: updatedRecords';
        } else {
            queryStr += ', ' + FieldApi + ' FROM ' + sObjectApi + ' WHERE Id IN: updatedRecords';
        }

		System.debug(queryStr);
		List<sObject> scope = new List<sObject>();
		scope = Database.query(queryStr);

		if(!scope.isEmpty()){
			execute(scope, FieldApi, sObjectApi, updatedRecords, fieldVal,fieldToAccessLevelMap);
		}
	}

	public static void execute(List<sObject> scope, String FieldApi, String sObjectApi, Set<Id> updatedRecords, List<String> fieldVal, Map<String,String> fieldToAccessLevelMap){
		SObjectType objToken = Schema.getGlobalDescribe().get(sObjectApi);
		List<sObject> newShares = new List<sObject>();
		List<sObject> allDeletes = new List<sObject>(); 

		if(objToken  != null){
			if(objToken.getDescribe().isCustom()){
				String delQuery = 'SELECT Id, ParentId, RowCause FROM ' + sObjectApi.remove('__c') + '__Share WHERE RowCause = \'manual\' AND ParentId IN: updatedRecords';
				System.debug('delQuery ' + delQuery);
				allDeletes = Database.query(delQuery);

				Schema.SObjectType testShareType = Schema.getGlobalDescribe().get(sObjectApi.remove('__c') + '__Share');
				for(sObject a : scope){
					if(fieldVal != null){
						for(String fil : fieldVal){
							SObject customShare = testShareType.newSObject();
							customShare.put('ParentId', String.valueOf(a.get('Id')));
							customShare.put('UserOrGroupId', String.valueOf(a.get(fil)));
							customShare.put('AccessLevel', fieldToAccessLevelMap.get(fil));
							customShare.put('RowCause', 'manual');
				
							newShares.add(customShare);
						}
					}
				}
			}
			else{
				String delQuery = 'SELECT Id, RowCause,'+sObjectApi+'Id'+' FROM ' + sObjectApi + 'Share WHERE RowCause = \'manual\' AND ' + sObjectApi + 'Id'+ ' IN: updatedRecords';

				allDeletes = Database.query(delQuery);

				Schema.SObjectType testShareType = Schema.getGlobalDescribe().get(sObjectApi + 'Share');
				for(sObject a : scope){
					if(fieldVal != null){
						for(String fil : fieldVal){
							SObject customShare = testShareType.newSObject();
							customShare.put(sObjectApi+'Id', String.valueOf(a.get('Id')));
							customShare.put('UserOrGroupId', String.valueOf(a.get(fil)));
							customShare.put(sObjectApi+'AccessLevel', fieldToAccessLevelMap.get(fil));
							customShare.put('RowCause', 'manual');
				
							newShares.add(customShare);
						}
					}
				}
			}
		}

		System.debug('allDeletes ' + allDeletes);
		System.debug('newShares ' + newShares);

		Database.delete(allDeletes, false);
		Database.SaveResult[] srList = Database.insert(newShares, false);
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				System.debug('Successfully inserted. ID: ' + sr.getId());
			}
			else {
				// Operation failed, so get all errors                
				for(Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');                    
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Fields that affected this error: ' + err.getFields());
				}
			}
		}
	}
}