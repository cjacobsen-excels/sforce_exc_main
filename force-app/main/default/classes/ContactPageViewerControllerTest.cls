@istest
public class ContactPageViewerControllerTest {
	@testSetup static void setup() {
        
    }

    public static testmethod void testCon(){
		User u = [SELECT Id FROM User where id =: UserInfo.getUserId() limit 1];
		u.Faculty_ID__c = 'test1234';

		Contact c = new Contact(LastName = 'testuser', Faculty_ID__c = 'test1234');
        insert c;

		update u;

		Related_Record_Columns__c rrc = new Related_Record_Columns__c(Name = 'test', Field_Name__c = 'Name', Label__c = 'Name', Target__c = 'none', Type__c = 'Text', Type_Attributes__c = '');
		insert rrc;

		Related_List_Settings__c rls = new Related_List_Settings__c(Name = 'test', Columns__c = rrc.Id ,Fields__c = 'Name',Layout_Order__c = 1,Related_Field_Api_Name__c = 'Name',Sobject_Api_Name__c = 'Contact',Sorted_By__c = 'Name');
		insert rls;

        System.runAs(u){
            ContactPageViewerController.getContactFromUser();
        }
    } 
}