public class MRK_MetaDTO {
    public String object_Z {get;set;} // in json: object
	public String foreignKey {get;set;} 
	public String creationType {get;set;} 
	public String runFunction {get;set;} 
	public String parentField {get;set;}
	public List<String> runFunctions {get;set;} 
	public Map<String, String> args {get;set;} 

	public MRK_MetaDTO(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'object') {
						object_Z = parser.getText();
					} else if (text == 'foreignKey') {
						foreignKey = parser.getText();
					} else if (text == 'creationType') {
						creationType = parser.getText();
					} else if (text == 'runFunction') {
						runFunction = parser.getText();
					} else if (text == 'parentField') {
						parentField = parser.getText();
					} else if (text == 'runFunctions') {
						//runFunctions = arrayOfString(parser);
					} else if (text == 'args') {
						args = mapStringToString(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'MRK_MetaDTO consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public static MRK_MetaDTO parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new MRK_MetaDTO(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}

	//Custom code
	public static Map<String, String> mapStringToString(System.JSONParser parser) {
		Map<String, String> res = new Map<String, String>();
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
			else {
				String currentText = parser.getText();
				if (parser.nextToken() != null) {
					String nextText = parser.getText();
					res.put(currentText, nextText);
				}
				else return res;
			}
		} while (depth > 0 && parser.nextToken() != null);
		
		return res;
	}

    /*public static List<String> arrayOfString(System.JSONParser p) {
        List<String> res = new List<String>();
        if (p.getCurrentToken() == null) p.nextToken();
		try{
			while (p.nextToken() != System.JSONToken.END_ARRAY) {
				res.add(p.getText());
			}
		}catch(Exception e){
			System.debug(e.getMessage());
		}
        return res;
    }*/

	public static string getGMTDate(DateTime dt){
        String dtStr = '';
        dtStr+=dt.Year() < 10 ? '0' + dt.Year()  + '-' : dt.Year() + '-';
        dtStr+=dt.Month() < 10 ? '0' + dt.Month()  + '-' : dt.Month() + '-';
        dtStr+=dt.Day() < 10 ? '0' + dt.Day()  + 'T' : dt.Day() + 'T';
        dtStr+=dt.Hour() < 10 ? '0' + dt.Hour() + ':' : dt.Hour() + ':';
        dtStr+=dt.Minute() < 10 ? '0' + dt.Minute() + ':' : dt.Minute() + ':';
        dtStr+=dt.Second() < 10 ? '0' + dt.Second(): dt.Second()+'';

        dtStr = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        return EncodingUtil.urlEncode(dtStr, 'UTF-8');
    }
}