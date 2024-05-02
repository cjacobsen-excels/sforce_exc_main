public class EventTask  implements Comparable{
    @AuraEnabled
    public String subject;
    @AuraEnabled
    public Id whatId;
    @AuraEnabled
    public String activityName ;
    @AuraEnabled
    public Date activityDate;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String taskSubType;
    @AuraEnabled
    public String taskDescription;

    public EventTask(String sub, Id wht, String aName, Date act,String st,String taskSubT,String descript) {
        subject = sub;
        whatId = wht;
        activityName = aName;
        activityDate = act;
        status = st;
        taskSubType=taskSubT;
        taskDescription=descript;
    }

    public Integer compareTo(Object compareTo) {
        EventTask compareEventTask = (EventTask)compareTo;
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (activityDate > compareEventTask.activityDate) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (activityDate < compareEventTask.activityDate) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        return returnValue;    

    }
}