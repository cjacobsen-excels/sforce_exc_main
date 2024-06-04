/*
*********************************************************
Apex Class Name    : CustomActivityController
Created Date       : Apr 12, 2024
@description       : This is class is used for LWC component to fetch the tasks for the activity section
@author            : Jake
Modification Log:
Ver   Date         Author                      Modification
1.0   04-2024      Jake                       Initial Version
1.1   05-2024      Jake                       Sort update
*********************************************************
*/
public without sharing class CustomActivityController { 
  static final String QUEUE_NAME = 'ADA Team Queue';
  static final String GROUP_TYPE = 'Queue'; 

  @AuraEnabled(cacheable=true)
  public static List<EventTask> getTasksList(Id contactRecId, Integer limitRecords) {
      Date dt;
      String adaCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ADA_Accommodation').getRecordTypeId();
      List<EventTask> taskEventList = new List<EventTask>();

      for (Task t : [SELECT Id, WhoId, WhatId, Type, CreatedDate, Subject, CallType, TaskSubtype, Status, LastModifiedDate, ActivityDate, What.Name, Description, Owner.Name
                     FROM Task
                     WHERE whoId = :contactRecId AND What.recordtype.Id != :adaCaseRecordTypeId
                     ORDER BY ActivityDate ASC
                     LIMIT :limitRecords]) {
          taskEventList.add(new EventTask(t.Id, t.Subject, t.WhatId, t.What.Name, t.ActivityDate, t.Status, t.TaskSubtype, t.Description, t.Owner.Name));
          dt = t.ActivityDate;
      }

      for (Event e : [SELECT Id, Subject, What.Name, WhatId, OwnerId, ActivityDate, LastModifiedDate, EventSubtype, Description, Owner.Name
                      FROM Event
                      WHERE whoId = :contactRecId
                      ORDER BY ActivityDate ASC
                      LIMIT :limitRecords]) {
          taskEventList.add(new EventTask(e.Id, e.Subject, e.WhatId, e.What.Name, e.ActivityDate, null, e.EventSubtype, e.Description, e.Owner.Name));
      }

      taskEventList.sort(); // Sort by ActivityDate in ascending order due to the compareTo implementation

      if (taskEventList.isEmpty()) {
          return null;
      } else {
          return taskEventList;
      }
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isNonADAmember() {
      List<GroupMember> gmList = [SELECT UserorGroupId, Group.Name
                                  FROM GroupMember
                                  WHERE Group.Name = :QUEUE_NAME
                                  AND UserOrGroupId = :UserInfo.getUserId()
                                  AND Group.Type = :GROUP_TYPE];
      return gmList.isEmpty();
  }
}