@isTest
public class CustomActivityControllerTest {
  @testSetup
  static void setupTestData() {
    List<Task> tasksToInsert = new List<Task>();
    List<Event> eventsToInsert = new List<Event>();

    Case testCase = new Case(
      Subject = 'Test Case',
      Description = 'This is a test case for unit testing',
      Status = 'New'
    );

    // Create test data: Contact
    Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');

    // Insert the test Contact
    insert testContact;

    // Insert the test Case
    insert testCase;

    // Create 20 Task records
    for (Integer i = 0; i < 5; i++) {
      tasksToInsert.add(
        new Task(
          Subject = 'Task ' + i, // Set the subject of the task
          ActivityDate = Date.today().addDays(i), // Set the activity date of the task
          // Set other required fields as needed
          WhoId = testContact.Id,
          whatid = testCase.Id
        )
      );
    }

    // Create 20 Event records
    for (Integer i = 0; i < 5; i++) {
      eventsToInsert.add(
        new Event(
          Subject = 'Event ' + i, // Set the subject of the event
          StartDateTime = DateTime.now().addDays(i), // Set the start date time of the event
          EndDateTime = DateTime.now().addDays(i + 1), // Set the end date time of the event
          // Set other required fields as needed
          WhoId = testContact.Id
        )
      );
    }

    // Insert the task and event records into the database
    insert tasksToInsert;
    insert eventsToInsert;
  }
  @isTest
  static void testMethod1() {
    Contact c = [SELECT id FROM Contact LIMIT 1];
    List<EventTask> eventTasklist = CustomActivityController.getTasksList(
      c.Id,
      3
    );
    Assert.areEqual(true, !eventTasklist.isEmpty(), 'test passed');
    Assert.areEqual(
      true,
      CustomActivityController.isNonADAmember(),
      'test passed'
    );
  }
}