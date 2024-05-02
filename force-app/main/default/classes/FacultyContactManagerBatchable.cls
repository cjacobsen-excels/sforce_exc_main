global class FacultyContactManagerBatchable implements Database.Batchable<SObject> {

	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'SELECT Id, FirstName, LastName, Faculty_User_Record__c, Manager__c, Last_Hire_Date__c, Original_Hire_Date__c, Name, Contact_Category__c FROM Contact WHERE Contact_Category__c = \'FC\'';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext context, List<Contact> scope) {
        System.debug(scope);
		EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName =:'Evaluation_Faculty_Evaluation_Due'];
		List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
		List<Task> tasksLst = new List<Task>();
		Faculty_Management__mdt oneYear = new Faculty_Management__mdt();
		Faculty_Management__mdt threeYear = new Faculty_Management__mdt();
		for(Faculty_Management__mdt fcmt : [SELECT Id, Date__c, Description__c, Description_Text_Area__c, ID__c, Name_Subject__c, Quantity__c, MasterLabel, DeveloperName FROM Faculty_Management__mdt]){
			if(fcmt.DeveloperName == 'Faculty_1_Year_Anniversary_Task'){
				oneYear = fcmt;
			}
			else if(fcmt.DeveloperName == 'Faculty_3_Year_Anniversary_Task'){
				threeYear = fcmt;
			}
		}
		
		//get date 30 days in the future for 3 year
		integer daysToAdd3 = threeYear.Quantity__c != null ? Integer.valueOf(threeYear.Quantity__c) : 30;
		Date today3 = System.today().addDays(daysToAdd3);
		Integer month3 = today3.Month();
		Integer day3 = today3.Day();
		Integer year3 = today3.Year();
		System.debug(today3);

		//get date 30 days in the future for 1 year
		integer daysToAdd1 = oneYear.Quantity__c != null ? Integer.valueOf(oneYear.Quantity__c) : 30;
		Date today1 = System.today().addDays(daysToAdd1);
		Integer month1 = today1.Month();
		Integer day1 = today1.Day();
		Integer year1 = today1.Year();
		System.debug(today1);

		for(Contact c : scope){
			if(c.Last_Hire_Date__c != null){
				Date hireDate = c.Last_Hire_Date__c;
				Integer hireMonth = hireDate.Month();
				Integer hireDay = hireDate.Day();
				Integer hireYear = hireDate.Year();

				System.debug(c.Last_Hire_Date__c);

				Integer numberOfYears1 = year1 - hireYear;
				Integer numberOfYears3 = year3 - hireYear;

				Integer multipleOf3 = math.mod(numberOfYears3,3);
				Decimal oneYearQuanity = 1;

				if(hireMonth == month1 && hireDay == day1 && numberOfYears1 == Integer.valueOf(oneYearQuanity)){
					Date newDate = Date.newInstance(year1, c.Last_Hire_Date__c.Month(), c.Last_Hire_Date__c.Day());
					Task t = new Task();
					t.Subject = oneYear.Name_Subject__c;
					t.Description = oneYear.Description_Text_Area__c;
					t.ActivityDate = newDate;
					t.OwnerId = c.Manager__c;
                    t.WhoId = c.Id;
					tasksLst.add(t);


					allmsg.add(createMail(et,c));

				}
				else if(hireMonth == month3 && hireDay == day3 && multipleOf3 == 0){
					Date newDate = Date.newInstance(year3, c.Last_Hire_Date__c.Month(), c.Last_Hire_Date__c.Day());
					Task t = new Task();
					t.Subject = threeYear.Name_Subject__c;
					t.Description = threeYear.Description_Text_Area__c;
					t.ActivityDate = newDate;
					t.OwnerId = c.Manager__c;
                    t.WhoId = c.Id;
					tasksLst.add(t);

					allmsg.add(createMail(et,c));
				}
			}
		}

		if(!tasksLst.isEmpty()){
			Database.insert(tasksLst,false);
			System.debug('task ' + tasksLst);
		}

		if(!allmsg.isEmpty() && !Test.isRunningTest()){
			List<Messaging.SendEmailResult> results = Messaging.sendEmail(allmsg,false);
			System.debug(results);
		}

	}

	global void finish(Database.BatchableContext context) {
		
	}

	global Messaging.SingleEmailMessage createMail(EmailTemplate et, Contact c){

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//mail.setTemplateId(et.Id);
		String body = 'You\'ve been assigned a new task to complete a Faculty Evaluation for ' + c.FirstName + ' ' + c.LastName + '\n';
		body += 'Please navigate to their Faculty Record using the link below to review their records for the appropriate period and then complete the evaluation using the button located in the top right of the screen.\n';
		body += URL.getSalesforceBaseUrl().toExternalForm()+'/'+c.Id;
		mail.setPlainTextBody(body);
		//mail.setCcAddresses(c.Manager__c);
		mail.setTargetObjectId(c.Manager__c);
		//mail.setSubject(et.subject);
		mail.setSubject('Faculty Evaluation Due for ' + c.FirstName + ' ' + c.LastName);
		//mail.setHTMLBody(et.Body);
		//mail.setWhatId(c.Faculty_User_Record__c);
		mail.setSaveAsActivity(false);

		return mail;
	}
}