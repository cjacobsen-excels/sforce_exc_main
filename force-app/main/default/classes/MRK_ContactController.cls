public class MRK_ContactController implements Callable{
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'setStaticFields' {
                return setStaticFields((sObject)args.get('object'), (Map<String, Object>)args.get('data'));
            }
        }
        return null;
    } 

    //Example - set fields on Contact and return
    public static SObject setStaticFields(sObject sObjectToSet, Map<String, Object> data) {

        return sObjectToSet;
    }
}