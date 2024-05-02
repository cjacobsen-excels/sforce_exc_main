global class SO_SchemaOptions extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('None', '');
        return defaultValue;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  values = new VisualEditor.DynamicPickListRows();
        VisualEditor.DataRow none = new VisualEditor.DataRow('None', '');
        values.addRow(none);
        List<Dynamic_Config__mdt> schemas = [SELECT DeveloperName, Label FROM Dynamic_Config__mdt LIMIT 200];
        for (Dynamic_Config__mdt schema : schemas) {
            VisualEditor.DataRow value = new VisualEditor.DataRow(schema.Label, schema.DeveloperName);
            values.addRow(value);
        }
        return values;
    }
}