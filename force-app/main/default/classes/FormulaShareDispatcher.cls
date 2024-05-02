public class FormulaShareDispatcher  {

	public static void shareRecords(String objectApi, Set<Id> updateIds){
		Map<String, List<Formula_Share_Custom__c>> FormulaShareCustomMap = new Map<String,List<Formula_Share_Custom__c>>();
		FormulaShareCustomMap = getShareRulesWithSettings();

		if(FormulaShareCustomMap.get(objectApi) != null){
			FormulaShareHelperTrigger.calculate(FormulaShareCustomMap.get(objectApi), objectApi, updateIds);
		}

	}

	public static Map<String, List<Formula_Share_Custom__c>> getShareRulesWithSettings(){
		Map<String, List<Formula_Share_Custom__c>> FormulaShareCustomMap = new Map<String,List<Formula_Share_Custom__c>>();
		for(Formula_Share_Custom__c fsc : [SELECT Id, Share_Level__c, Formula_Field_API__c, isActive__c, sObject_API__c FROM Formula_Share_Custom__c WHERE isActive__c = TRUE]){
			if(FormulaShareCustomMap.containsKey(fsc.sObject_API__c)) {
				List<Formula_Share_Custom__c> fscLst = FormulaShareCustomMap.get(fsc.sObject_API__c);
				fscLst.add(fsc);
				FormulaShareCustomMap.put(fsc.sObject_API__c, fscLst);
			} else {
				FormulaShareCustomMap.put(fsc.sObject_API__c, new List<Formula_Share_Custom__c> { fsc });
			}
		}

		return FormulaShareCustomMap;
	}

	public static Map<String,String> getShareRules(){
		Map<String, String> objectToFields = new Map<String,String>();
		for(Formula_Share_Custom__c fsc : [SELECT Id, Share_Level__c, Formula_Field_API__c, isActive__c, sObject_API__c FROM Formula_Share_Custom__c WHERE isActive__c = TRUE]){
			if(objectToFields.get(fsc.sObject_API__c) != null){
				String fields = objectToFields.get(fsc.sObject_API__c);
				fields += ','+fsc.Formula_Field_API__c;
				objectToFields.put(fsc.sObject_API__c, fields);
			}
			else{
				objectToFields.put(fsc.sObject_API__c, fsc.Formula_Field_API__c);
			}
		}

		return objectToFields;
	}

	public static Map<String,String> getShareRulesCourseOfferings(){
		Map<String,String> fieldToAccessLevelMap = new Map<String,String>();
		for(Formula_Share_Custom__c fsc : [SELECT Id, Share_Level__c, Formula_Field_API__c, isActive__c, sObject_API__c FROM Formula_Share_Custom__c WHERE isActive__c = TRUE AND sObject_API__c = 'hed__Course_Offering__c']){
			fieldToAccessLevelMap.put(fsc.Formula_Field_API__c, fsc.Share_Level__c);
		}

		return fieldToAccessLevelMap;
	}

	public static Set<Id> getChangedRecords(List<sObject> updatedRecords, Map<Id,sObject> oldMap, String sObApi){
		Map<String, String> objectToFields = new Map<String,String>();
		Set<Id> updateRecords = new Set<Id>();
		objectToFields = getShareRules();

		String fields = objectToFields.get(sObApi);
		List<String> fieldsLst = new List<String>();
		if(fields != null){
			fieldsLst = fields.split(',');
		}

		for(sObject o : updatedRecords){
			for(String fld : fieldsLst){
				sObject oldObj = oldMap.get(String.valueOf(o.get('Id')));
				if(String.valueOf(o.get(fld)) != String.valueOf(oldObj.get(fld))){
					updateRecords.add(String.valueOf(o.get('Id')));
				}
			}
		}

		return updateRecords;
	}

	public static Set<Id> getChangedChildRecords(Set<Id> parentIds, String childObjApi, String parentFieldApi){
		Set<Id> updateRecords = new Set<Id>();
		String query = 'SELECT Id, ' + parentFieldApi + ' FROM ' + childObjApi + ' WHERE ' + parentFieldApi + ' IN: parentIds';
		System.debug(query);
		for(sObject o : Database.query(query)){
			updateRecords.add(String.valueOf(o.get('Id')));
		}
		System.debug(updateRecords);
		return updateRecords;
	}

	public static void setSharingCourseOffering(Set<Id> insertedOrUpdated){
		List<hed__Course_Offering__c> courseOfferings = new List<hed__Course_Offering__c>();
		List<AccountShare> deleteCourseShare = new List<AccountShare>();
		List<AccountShare> newCourseShare = new List<AccountShare>();
		Set<Id> courseAccIds = new Set<Id>();
		Set<Id> CAUserId = new Set<Id>();
		Set<Id> CAonCallUserId = new Set<Id>();
		Set<Id> FacultyUserID = new Set<Id>();
		for(hed__Course_Offering__c co : [SELECT Id, hed__Course__r.hed__Account__c,CAUserId__c,FacultyUserID__c FROM hed__Course_Offering__c WHERE Id IN: insertedOrUpdated]){
			courseAccIds.add(co.hed__Course__r.hed__Account__c);
			CAUserId.add(co.CAUserId__c);
			FacultyUserID.add(co.FacultyUserID__c);
			courseOfferings.add(co);
		}

		Map<String,String> fieldToAccessLevelMap = new Map<String,String>();
		fieldToAccessLevelMap = getShareRulesCourseOfferings();

		deleteCourseShare = [SELECT Id, UserOrGroupId, AccountID FROM AccountShare WHERE AccountID IN: courseAccIds 
						AND (UserOrGroupId IN: CAUserId OR UserOrGroupId IN: FacultyUserID)];

		for(hed__Course_Offering__c co : courseOfferings){
			if(co.CAUserId__c != null && co.CAUserId__c != 'null' && co.CAUserId__c != ''){
				AccountShare customShare1 = new AccountShare();
				customShare1.AccountId = co.hed__Course__r.hed__Account__c;
				customShare1.UserOrGroupId = co.CAUserId__c;
				customShare1.AccountAccessLevel = fieldToAccessLevelMap.get('CAUserId__c') == null ? 'Read' : fieldToAccessLevelMap.get('CAUserId__c');
				customShare1.OpportunityAccessLevel='Read';	
				newCourseShare.add(customShare1);
			}

			if(co.FacultyUserID__c != null){
				AccountShare customShare3 = new AccountShare();
				customShare3.AccountId = co.hed__Course__r.hed__Account__c;
				customShare3.UserOrGroupId = co.FacultyUserID__c;
				customShare3.AccountAccessLevel = fieldToAccessLevelMap.get('FacultyUserID__c') == null ? 'Read' : fieldToAccessLevelMap.get('FacultyUserID__c');
				customShare3.OpportunityAccessLevel='Read';	
				newCourseShare.add(customShare3);
			}
		}

		System.debug(deleteCourseShare);
		System.debug(newCourseShare);
		DataBase.delete(deleteCourseShare, false);
		//DataBase.insert(newCourseShare, false);

		Database.SaveResult[] srList = DataBase.insert(newCourseShare, false);
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