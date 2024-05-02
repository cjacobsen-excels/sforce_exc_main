global class FormulaShareHelperBatch implements Database.Batchable<SObject> {
	
	Public List<Formula_Share_Custom__c> fieldSettings; 
	Public String sObjectApi;
	public List<String> fieldVal;
	Public String FieldApi;

	global FormulaShareHelperBatch(List<Formula_Share_Custom__c> fieldSettings, String sObjectApi) {
		this.fieldVal = new List<String>();
		this.fieldSettings = fieldSettings;
		this.sObjectApi = sObjectApi;

		for(Formula_Share_Custom__c fsc: fieldSettings){
			this.fieldVal.add(fsc.Formula_Field_API__c);

			if(this.FieldApi == null){
				this.FieldApi = fsc.Formula_Field_API__c;
			}
			else{
				this.FieldApi += ',' + fsc.Formula_Field_API__c;
			}
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext context) {
		String queryStr = 'SELECT Id, ' + FieldApi + ' FROM ' + sObjectApi + ' WHERE Id != null ';
		for(String fil : fieldVal){
			queryStr += ' AND (' + fil + ' != null AND ' + fil + ' != \'\')';
		}
		System.debug(queryStr);
		return Database.getQueryLocator(queryStr);
	}

   	global void execute(Database.BatchableContext context, List<sObject> scope) {

		Map<String,String> fieldToAccessLevelMap = new Map<String,String>();
		for(Formula_Share_Custom__c fsc: fieldSettings){
			fieldToAccessLevelMap.put(fsc.Formula_Field_API__c,fsc.Share_Level__c);
		}

		SObjectType objToken = Schema.getGlobalDescribe().get(sObjectApi);
		List<sObject> newShares = new List<sObject>();
		List<sObject> allDeletes = new List<sObject>(); 

		Set<Id> shareUserIds = new Set<Id>();
		for(sObject a : scope){
			for(String fil : fieldVal){
				shareUserIds.add(String.valueOf(a.get(fil)));
			}
		}

		if(objToken  != null){
			if(objToken.getDescribe().isCustom()){
				String delQuery = 'SELECT Id, ParentId, RowCause FROM ' + sObjectApi.remove('__c') + '__Share WHERE RowCause = \'manual\' AND ParentId IN: shareUserIds';

				System.debug(delQuery);
				allDeletes = Database.query(delQuery);

				Schema.SObjectType testShareType = Schema.getGlobalDescribe().get(sObjectApi.remove('__c') + '__Share');
				for(sObject a : scope){
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
			else{
				String delQuery = 'SELECT Id,'+sObjectApi+'Id'+', RowCause FROM ' + sObjectApi + 'Share WHERE RowCause = \'manual\' AND ' + sObjectApi + 'Id'+ ' IN: shareUserIds';

				allDeletes = Database.query(delQuery);

				Schema.SObjectType testShareType = Schema.getGlobalDescribe().get(sObjectApi + 'Share');
				for(sObject a : scope){
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
	
	global void finish(Database.BatchableContext context) {
		
	}
}