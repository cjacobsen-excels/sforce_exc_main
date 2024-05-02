public class MRK_TaskModel {
    public String marketoGUID;
    public Integer leadId;
    public String activityDate;
    public Integer activityTypeId;
    public Integer campaignId;
    public Integer primaryAttributeValueId;
    public String primaryAttributeValue;
    public List<Attribute> attributes;
    public List<Field> fields;

    public class Attribute{
        public String name;
        public String value;
    }

    public class Field{
        public String name;
        public String newValue;
        public String oldValue;
    }
}