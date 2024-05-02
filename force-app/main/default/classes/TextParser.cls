public class TextParser {
    @InvocableMethod(label='Parse Text' description='Parses the input text into a list of strings with line breaks')
    public static List<String> parseText(List<String> inputTexts) {
        String inputText = inputTexts[0];
        inputText = inputText.substring(1, inputText.length()-1);  // Remove leading and trailing square brackets
        List<String> records = inputText.split(',');
        String outputText = String.join(records, ',\n');  // Join the records with a comma and a line break
        return new List<String>{outputText};
    }
}