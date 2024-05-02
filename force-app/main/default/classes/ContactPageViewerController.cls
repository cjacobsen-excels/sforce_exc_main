public class ContactPageViewerController  {

	@AuraEnabled
	public static ReturnDataModel getContactFromUser(){
		ReturnDataModel rdm = new ReturnDataModel();
		rdm.contact = new Contact();
		rdm.relatedListItems = new List<RecListData>();

		User u = [SELECT Id, ContactID, Faculty_ID__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

		if(u != null && u.Faculty_ID__c != null){
            List<Contact> conLst = new List<Contact>();
			conLst = [SELECT Id, Name, Faculty_ID__c FROM Contact WHERE Faculty_ID__c =: u.Faculty_ID__c LIMIT 1];
            System.debug('u.Faculty_ID__c ' + u.Faculty_ID__c);
            System.debug('conLst ' + conLst);
            if(!conLst.isEmpty()){
            	rdm.contact = conLst[0];
            }
		}

		for(Related_List_Settings__c rls : [SELECT Id, Show_New_Button__c, Columns__c,Fields__c,Layout_Order__c,Related_Field_Api_Name__c,Sobject_Api_Name__c,Sorted_By__c
											FROM Related_List_Settings__c
											ORDER BY Layout_Order__c ASC]){
			RecListData dr = new RecListData();
			dr.Fields = rls.Fields__c;
			dr.Layout_Order = Integer.valueOf(rls.Layout_Order__c);
			dr.Related_Field_Api_Name = rls.Related_Field_Api_Name__c;
			dr.Sobject_Api_Name = rls.Sobject_Api_Name__c;
			dr.Sorted_By = rls.Sorted_By__c;
			dr.Show_New = rls.Show_New_Button__c;

			List<String> colStr = new List<String>();
			List<cols> colLst = new List<cols>();
			if(rls.Columns__c != '' && rls.Columns__c != null){
				colStr = rls.Columns__c.replaceAll( '\\s+', '').split(',');
			}
			for(Related_Record_Columns__c rrc : [SELECT Id, Field_Name__c, Label__c, Target__c, Type__c, Type_Attributes__c FROM Related_Record_Columns__c WHERE Id IN: colStr]){
				cols cls = new cols();
				label l = new label();
				l.fieldName = rrc.Type_Attributes__c;

				cls.fieldName = rrc.Field_Name__c;
				cls.label = rrc.Label__c;
				cls.target = rrc.Target__c;
				cls.type = rrc.Type__c;
				cls.typeAttributes = l;

				colLst.add(cls);
			}
			dr.Columns = colLst;

			System.debug(colLst);

			rdm.relatedListItems.add(dr);
		}

		return rdm;
	}

	public class ReturnDataModel {
		@AuraEnabled
		public Contact contact;

		@AuraEnabled
		public List<RecListData> relatedListItems;
	}

	public class RecListData{
		@AuraEnabled
		public String Fields;
		@AuraEnabled
		public Boolean Show_New;
		@AuraEnabled
		public Integer Layout_Order;
		@AuraEnabled
		public String Related_Field_Api_Name;
		@AuraEnabled
		public String Sobject_Api_Name;
		@AuraEnabled
		public String Sorted_By;
		@AuraEnabled
		public List<cols> Columns;
	}

	public class cols{
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String fieldName;
		@AuraEnabled
		public String type;
		@AuraEnabled
		public String target;
		@AuraEnabled
		public label typeAttributes;
	}

	public class label{
		@AuraEnabled
		public String fieldName;
	}
}