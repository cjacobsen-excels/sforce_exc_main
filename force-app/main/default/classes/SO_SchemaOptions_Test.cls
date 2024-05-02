@isTest
public class SO_SchemaOptions_Test {
	    
    @isTest(SeeAllData=true) public static void testSchemaOptions() {
        SO_SchemaOptions options = new SO_SchemaOptions();
        VisualEditor.DynamicPickListRows rows = options.getValues();
        VisualEditor.DataRow values = options.getDefaultValue();
    }
}