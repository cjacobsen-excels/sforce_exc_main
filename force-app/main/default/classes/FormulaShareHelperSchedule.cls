global class FormulaShareHelperSchedule implements Schedulable {
	/**
	 * @description Executes the scheduled Apex job. 
	 * @param sc contains the job ID
	 */ 
	global void execute(SchedulableContext sc) {
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

		System.debug(FormulaShareCustomMap.keySet());
			
		for(String obj : FormulaShareCustomMap.keySet()){
			FormulaShareHelperBatch fshb = new FormulaShareHelperBatch(FormulaShareCustomMap.get(obj), obj);
			Database.executeBatch(fshb, 200);
		}
	}
}