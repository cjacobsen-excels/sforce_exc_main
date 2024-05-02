public class CustomActCtrl {


    @AuraEnabled 


    public static List<task> findTask(){


        return [SELECT Id,Subject,Description,ActivityDate,Who.Name,WhoId,Priority


                FROM Task


                LIMIT 10];


    }


}