@isTest
public class TextParserTest {

    @isTest
    static void testParseText() {
        // Test case 1: Test with multiple records
        List<String> inputTexts1 = new List<String>{'[Record1, Record2, Record3]'};
        List<String> expectedOutput1 = new List<String>{'Record1,\n Record2,\n Record3'};
        List<String> actualOutput1 = TextParser.parseText(inputTexts1);
        System.assertEquals(expectedOutput1, actualOutput1);

        // Test case 2: Test with a single record
        List<String> inputTexts2 = new List<String>{'[SingleRecord]'};
        List<String> expectedOutput2 = new List<String>{'SingleRecord'};
        List<String> actualOutput2 = TextParser.parseText(inputTexts2);
        System.assertEquals(expectedOutput2, actualOutput2);

        // Test case 3: Test with an empty input
        List<String> inputTexts3 = new List<String>{'[]'};
        List<String> expectedOutput3 = new List<String>{''};
        List<String> actualOutput3 = TextParser.parseText(inputTexts3);
        System.assertEquals(expectedOutput3, actualOutput3);
    }
}