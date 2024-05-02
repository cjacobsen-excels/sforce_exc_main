global class UserContactRefreshLinkSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
		
		List<User> users = new List<User>();
		List<Contact> updateContact = new List<Contact>();
		Map<String,String> facMap = new Map<String,String>();
		for(User u : [SELECT Id, Faculty_ID__c, isActive FROM User WHERE isActive = true and Faculty_ID__c != '']){
			users.add(u);
			facMap.put(u.Faculty_ID__c, u.Id);
		}

		for(Contact c : [SELECT Id, Faculty_ID__c, Faculty_User_Record__c FROM Contact WHERE Faculty_ID__c != '']){
			c.Faculty_User_Record__c = facMap.get(c.Faculty_ID__c);
			updateContact.add(c);
		}

		if(!updateContact.isEmpty()){
			Database.update(updateContact,false);
		}

	}
}