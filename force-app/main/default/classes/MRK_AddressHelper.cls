public class MRK_AddressHelper implements Callable{
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'breakApartAddress' {
                return breakApartAddress((sObject)args.get('object'), (String)args.get('data'), (String)args.get('mailingOrBilling'));
            }
        }
        return null;
    }

    public static SObject breakApartAddress(sObject sObjectToSet, String addressData, String mailingOrBilling) {
        String streetValue;
        Pattern streetPattern = Pattern.compile('(^\\d+\\s[A-z]+\\s[A-z]+\\.).+');
        Matcher streetMatcher = streetPattern.matcher(addressData);
        if (streetMatcher.matches()) {
            streetValue = streetMatcher.group(1);
        } 
        else return sObjectToSet;
        
        String remainingAddress = addressData.substringAfter(streetValue).trim();
        String cityValue = remainingAddress.substringBefore(',').trim();
        String stateValue = remainingAddress.substringAfter(',').trim().substringBefore(' ');
        String zipValue = remainingAddress.substringAfter(stateValue).trim();

        System.debug(mailingOrBilling);

        if (mailingOrBilling.trim() == 'Billing') {
            sObjectToSet.put('BillingStreet', streetValue);
            sObjectToSet.put('BillingCity', cityValue);
            sObjectToSet.put('BillingState', stateValue);
            sObjectToSet.put('BillingPostalCode', zipValue);
        }
        else if (mailingOrBilling.trim() == 'Mailing') {
            sObjectToSet.put('MailingStreet', streetValue);
            sObjectToSet.put('MailingCity', cityValue);
            sObjectToSet.put('MailingState', stateValue);
            sObjectToSet.put('MailingPostalCode', zipValue);
        }
        else {
            System.debug('Please enter the Address to break apart starting with the Billing or Mailing address e.g. "Billing | $$..."');
            return sObjectToSet;
        }
       
        return sObjectToSet;
    }
}