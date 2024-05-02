public class ShareRecordHandler  {

	public static ContactShare createShare(Id conId, Id facultyId){
		ContactShare conShr  = new ContactShare();
		conShr.ContactId = conId;
		conShr.UserOrGroupId = facultyId;
		conShr.ContactAccessLevel = 'Edit';
		conShr.RowCause = Schema.ContactShare.RowCause.Manual;

		return conShr;
	}
}