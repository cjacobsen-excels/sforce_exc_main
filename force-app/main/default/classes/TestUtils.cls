@isTest
public class TestUtils{
    public static Integer rnd = 0;

    public static User adminUser
    {
        get
        {
            if (adminUser == null)
            {
                Profile p = [select id, name from Profile where name = 'System Administrator' LIMIT 1];
                adminUser = [SELECT Id FROM User WHERE ProfileId = :p.Id AND IsActive = true LIMIT 1];
            }
            return adminUser;
        }
        private set;
    }

    public static Id getAccountRecordType(String type){
        Id thisId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get(type).getRecordTypeId();
        return thisId;
    }

    public static Id getCaseRecordType(String type){
        Id thisId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get(type).getRecordTypeId();
        return thisId;
    }
    
    public static Attachment createAttachment(String name, String d, Blob b, Id ParentId){
        Attachment a = new Attachment();
        a.Name = name;
        a.Description = d;
        a.Body = b;
        a.ParentId = ParentId;
        system.debug('TestUtil Application created = '+a);
        return a;
    }

    public static List<Contact> makeContacts (Integer size, String firstName, string LastName, Boolean isInsert){
        List<Contact> contactsToReturn = new List<Contact>();

        for(integer i = 0; i < size; i++ ){
            contactsToReturn.add(new contact(firstname = firstName + i, lastName = lastName + i));
        }

        if( isInsert) {
            insert contactsToReturn;
        }

        return contactsToReturn;
    }

    public static Contact makeContact(Boolean isInsert){
        Contact c = new Contact();
        c.FirstName = 'Homer';
        c.LastName = 'Simpson';
        
        if(isInsert){
            insert c;
        }
        
        return c;
    }

    public static List<Case> createCases (Integer size, ID accountID, string name, Boolean isInsert){
        List<Case> casesToReturn = new List<Case>();

        for(integer i = 0; i < size; i++ ){
            Case ca = new case();
            ca.recordTypeID =  getCaseRecordType('Other');
            if(accountID != null ){
                ca.accountID = accountID;
            }
            casesToReturn.add(ca);
        }

        if( isInsert) {
            insert casesToReturn;
        }

        return casesToReturn;
    }


    public static Contact createContactWithAccount(Account account)
    {
        Contact contact = TestUtils.makeContact(false);
        contact.AccountId = account.Id;
        insert contact;
        return contact;
    }

    public static Account createAccount(String name, Id recordTypeId){
        Account a = new Account();
        a.Name = name;
        a.Status__c = '5 Approved';
        a.RecordTypeId = recordTypeId;
        return a;
    }

    public static User buildUser(Profile profile)
    {
        rnd++;
        String testemail = 'ciee-bw-test-2@test.test';
        User user = new User(ProfileId = profile.id, username = testemail + rnd, email = testemail,
            emailencodingkey = 'UTF-8', localesidkey = 'en_US',
            languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
            alias='cspu', lastname='lastname');
        return user;
    }

    public static User getTestUser(String userName, String profileName)
    {
        String profileId;
        try
        {
            profileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        }
        catch(Exception ex)
        {
            System.debug(ex);
            System.assert(false, 'No profile exists with name'+ profileName);
        }
        User testUser = new User();
        testUser.LastName = 'test ' + UserName;
        testUser.Alias = UserName;
        testUser.Email = UserName+'@test.com';
        testUser.Username = UserName+UserName+'@test.com';
        testUser.CommunityNickname = 'a'+UserName;
        testUser.TimeZoneSidKey = 'America/New_York';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.IsActive = true;

        return testUser;
    }
    
    public static List<Lead> createLeads(String companyName, String lstname, Integer size, Boolean isInsert){
        List<Lead> LeadList = new List<Lead>();
        
        for(integer i = 0; i < size; i++ ){
            LeadList.add(new Lead(Company = companyName + i, LastName = lstname + i));
        }
        
        if(isInsert){
            insert LeadList;
        }
        
        return LeadList;
    }
    
    public static Lead makeLead(Boolean isInsert){
        Lead l = new Lead();
        l.Company = 'Bluewolf';
        l.LastName = 'Simpson';
        
        if(isInsert){
            insert l;
        }
        
        return l;
    }
    
    public static Campaign makeCampaign(){
        Campaign cmpgn = new Campaign();
        cmpgn.Name = 'testCampaign';
        
        return cmpgn;
    }
    
    public static List<Campaign> createCampaigns(String nme, Integer size, Boolean isInsert){
        List<Campaign> cmpgns = new  List<Campaign>();
        
        for(integer i = 0; i < size; i++ ){
            cmpgns.add(new Campaign(Name = nme + i));
        }
        
        if(isInsert){
            insert cmpgns;
        }
        
        return cmpgns;
    }
    
    public static CampaignMember buildCampaignMember(Campaign cmpgn, Contact c, Lead l){
        
        CampaignMember cmpmember = new CampaignMember();
        
        cmpmember.CampaignId = cmpgn.Id;
        
        cmpmember.ContactId = c.Id;
        
        cmpmember.LeadId = l.Id;
        
        return cmpmember;
        
    }
    
    public static List<CampaignMember> createCampaignMembers(Campaign cmpgn, Integer size, Boolean isInsert){
        List<CampaignMember> cmpgnmembers = new  List<CampaignMember>();

        List<Contact> contactList = makeContacts (size, 'Peter', 'Griffin', true);
        List<Lead> leadList = createLeads('Family Guy', 'Simpson', size, true);
        
        for(integer i = 0; i < size; i++ ){
            
            CampaignMember cmpgnMember = new CampaignMember();
            cmpgnMember.ContactId = contactList[i].Id;
            cmpgnMember.LeadId = leadList[i].Id;
            
            if(cmpgn.Id != null){
                cmpgnMember.CampaignId = cmpgn.Id;
            }
            
            cmpgnmembers.add(cmpgnMember);
        }
        
        if(isInsert){
            insert cmpgnmembers;
        }
        
        return cmpgnmembers;
    }
    
    public static List<Campaign> createChildCampaigns(Id parentCampgnId, String cmpgnName, Integer size, Boolean isInsert){
        List<Campaign> childCampgns = new List<Campaign>();
        
        for(integer i = 0; i < size; i++ ){
            
            Campaign childCampgn = new Campaign(Name = cmpgnName + i); 
            
            if(parentCampgnId != null){
                childCampgn.ParentId = parentCampgnId;
            }
            
            childCampgns.add(childCampgn);
        }
        
        if(isInsert){
            insert childCampgns;
        }
        
        return childCampgns;
        
    }
    
    public static List<QueueSObject> createQueues(String queueName, String groupType, String queueType, Integer size){
        
        List<QueueSObject> createdQueues = new List<QueueSObject>();
        List<Group> groups = TestUtils.createGroups('test group', groupType, size);
        
        for(Integer i=0;i < size;i++){
            QueueSObject newQueue = new QueueSObject();
            newQueue.QueueId = groups[i].Id;
            newQueue.SobjectType = queueType;
            createdQueues.add(newQueue);
        }
        return createdQueues;
    }
    
    public static QueueSObject testQueueCreation(Group g, String SObjectType){
        
        QueueSObject newQueue = new QueueSObject();
        newQueue.QueueId = g.id;
        newQueue.SObjectType = SObjectType;

        return newQueue;
    }
    
    public static Group createGroup(String groupName, String groupType, Boolean isInsert){
        
        Group grp = createGroups(groupName, groupType, 1)[0];
        
        if(isInsert){
            insert grp;
        }
        return grp;
    }
    
    public static List<Group> createGroups(String groupName, String groupType, Integer size){
        
        List<Group> createdGroups = new List<Group>();
        
        for(integer i = 0;i < size;i++){
            Group newGroup = new Group();
            newGroup.Name = groupName + i;
            newGroup.Type = groupType;
            createdGroups.add(newGroup);
        }
        
        return createdGroups;
    }
    
    public static Assignment_Group_Name__c createAssignmentGroupName(String assignmentGroupName, String assignmentGroupType, Boolean isInsert){
        
        Assignment_Group_Name__c ag = new Assignment_Group_Name__c ();
        ag.Name = assignmentGroupName;
        ag.Type__c = assignmentGroupType;
        
        if(isInsert){
            insert ag;
        }
        
        return ag;
    }
    
    public static Assignment_Group_Queues__c createAssignmentGroupQueue(Group createdGroup, Assignment_Group_Name__c assignmentGroup){
        
        Assignment_Group_Queues__c agQueue = new Assignment_Group_Queues__c();
        agQueue.Name = createdGroup.Name;
        agQueue.Assignment_Group_Name__c = assignmentGroup.Id;
        
        return agQueue;
    }

    public static Assignment_Groups__c createAssignmentGroups(Id createdUser, Id agNameId){
        
        Assignment_Groups__c newAssignmentGroup = new Assignment_Groups__c();

        newAssignmentGroup.User__c = createdUser;
        newAssignmentGroup.Group_Name__c = agNameId;

        return newAssignmentGroup;
    }
    
}