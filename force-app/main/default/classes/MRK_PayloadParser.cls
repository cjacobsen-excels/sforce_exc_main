public with sharing class MRK_PayloadParser {
    //Public variables for use in recursive function
    public static String previousKey;
    public static Map<String, Object> keyValueHierarchy = new Map<String, Object>();
    public static MRK_MetaDTO topLevelMeta;
    public static sObject topLevelSObject;
    public static List<sObject> innerResults = new List<sObject>();
    public static Integer innerResultsIndex = 0;
    
    public static String loadSchema(String schemaName) {
        MRK_Payload_Parser__mdt schema = [SELECT json__c FROM MRK_Payload_Parser__mdt WHERE DeveloperName = :schemaName];
        return schema.json__c;
    }
    
    public static Marketo_Log__c processData(String schemaName, String payloadData, Marketo_Log__c ml) {
        Map<String, Object> jsonSchema;
        Map<String, Object> payload;
        Map<String, Object> jsonMap = new Map<String, Object>();
        try {
            jsonSchema = (Map<String, Object>)JSON.deserializeUntyped(loadSchema(schemaName));
            payload = (Map<String, Object>)JSON.deserializeUntyped(payloadData);
            System.debug(payload);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            return ml;
        }

        topLevelMeta = MRK_MetaDTO.parse(JSON.serialize(jsonSchema.get('_meta')));

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(topLevelMeta.object_Z);
        SObject focusSObject;
        String query;
       
        //Query for sObject based on foreign key, if it exists
        if (!String.isBlank(topLevelMeta.foreignKey)) {
            //Find out which Payload field maps to the Foreign Key
            String payloadForeignKey;
            String payloadForeignKeyValue;
            for (String key : jsonSchema.keySet()) {
                String value = String.valueOf(jsonSchema.get(key));
                if (value == topLevelMeta.foreignKey) {
                    payloadForeignKey = key;
                    System.debug(payload.get(key));
                    payloadForeignKeyValue = String.valueOf(payload.get(key));
                    break;
                }
            }
            if (!String.isBlank(payloadForeignKeyValue)) {
                query = 'SELECT Id';
                if (payloadForeignKey != 'Id' && payloadForeignKey != null) {
                   query += ', ' + payloadForeignKey;
                }
                query += ' FROM ' + topLevelMeta.object_Z + ' WHERE ' + topLevelMeta.foreignKey + ' = :payloadForeignKeyValue LIMIT 1';
                List<SObject> queriedSObjects = Database.query(query);
                if (queriedSObjects.size() > 0) {
                    focusSObject = queriedSObjects[0];
                }
            }
        }

        //Create an empty initial focusSObject if it wasn't queried
        String creationType = topLevelMeta.creationType;
        if (focusSObject == null) {
            if (!String.isBlank(creationType)) {
                if (creationType == 'UPSERT_ONLY' || creationType == 'INSERT_ONLY') {
                    focusSObject = sObjType.newSObject();
                }
                else if (creationType == 'UPDATE_ONLY') {
                    System.debug('ERROR: No record found for Update Only.');
                    return ml;
                } 
                else {
                    System.debug('Invalid Creation Type.');
                    return ml;
                }
            }

            focusSObject = sObjType.newSObject(); 
        }

        topLevelSObject = focusSObject;
        List<SObject> results = iterateJSON(jsonSchema, payload, focusSObject, new List<SObject>(), null, new List<Object>()); 
        
        for (SObject result : results) {
            system.debug(result);
        }

        Database.UpsertResult[] srList = Database.upsert(results,false);
        
        if(ml.Id != null){
            Integer i = 0;
            Boolean hasFail = false;
            for (Database.UpsertResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted:: ' + sr.getId());
                }
                else {
                    hasFail = true;
                }
                i++;
            }

            if(hasFail){
                ml.Number_Of_Retries__c = ml.Number_Of_Retries__c + 1;
                ml.Include_in_Retries__c = false;
                ml.Status__c = 'Success';
            }
            else{
                ml.Number_Of_Retries__c = ml.Number_Of_Retries__c + 1;
                ml.Include_in_Retries__c = true;
                ml.Status__c = 'Fail';
            }
        }

        return ml;
    }
    
    public static List<SObject> iterateJSON(Map<String, Object> jsonSchema, Map<String, Object> payload, SObject focusSObject, List<SObject> results, String payloadSubKey, List<Object> payloadSubObjects) {
        MRK_MetaDTO innerMeta;
        SObject currentSObject = focusSObject;
        String payloadValue;
        Boolean addedSObjects = false;
        Map<String, String> mapOfExternalIdRefs = new Map<String,String>();
        Schema.SObjectType currentExternalMap;

        //Iterate over the JSON Schema (Metadata record)
        for (String key : jsonSchema.keySet()) {
            Object value = jsonSchema.get(key);
			//Parse each meta key past the top level meta
            if (key == '_meta' && value != topLevelMeta) {
                innerMeta = MRK_MetaDTO.parse(JSON.serialize(value));

                Schema.SObjectType sObjType;
                if (!String.isBlank(innerMeta.object_Z)) {
                    sObjType = Schema.getGlobalDescribe().get(innerMeta.object_Z);
                    currentSObject = sObjType.newSObject();
                }
                else {
                    System.debug('Please specify an Object in the inner _meta tag.');
                    return new List<SObject>();
                }
                
                String functionToRun = innerMeta.runFunction;
                if (!String.isBlank(functionToRun)) {
                    Map<String, Object> args = new Map<String, Object>();
                    args.put('object', currentSObject);
                    if (innerMeta.args != null) {
                        args.putAll(innerMeta.args);
                    }

                    //Find the function to run and run it
                    String controllerToReference = functionToRun.subStringBefore('.');
                    String functionToCall = functionToRun.substringAfter('.');
                    Type classType = Type.forName(controllerToReference);
                    if (classType != null) {
                        Callable callableInstance = (Callable)classType.newInstance();
                        currentSObject = (SObject)callableInstance.call(functionToCall, args);
                    }
                }
    
                continue;
            }

            //Check if the Value is a String
            else if (value instanceOf String) {
                System.debug(value instanceOf String);
                System.debug(value);
                System.debug(key);
                String valueString = String.valueOf(value);
                //* denotes required
                if (key.contains('*')) {
                    key = key.substringAfter('*');
                    payloadValue = (String)payload.get(key);
                    if (String.isBlank(payloadValue)) {
                        System.debug('The payload does not have a value for the required Schema key ' + key);
                        return new List<SObject>();
                    }
                }

                //$ denotes reserved String afterwards
                if (key.contains('$') && !key.contains('$$')) {
                    String reservedString = key.subStringAfter('$').subStringBefore('.');
                    if (!String.isBlank(reservedString)) {
                        if (reservedString == 'PARENT') {
                            String fieldToGrab = key.subStringAfter('.');
                            //Grab the Parent (Parent Contact.Id) field and put it into the given field (Parent_Contact__c)
                            Object topLevelFieldValue = topLevelSObject.get(fieldToGrab);
                            currentSObject.put(valueString, topLevelFieldValue);
                            //Handle any Inner Results available
                            for (Integer i = 0; i < payloadSubObjects.size(); i++) {
                                if (innerResults.size() > innerResultsIndex + i) {
                                    innerResults[innerResultsIndex + i].put(valueString, topLevelFieldValue);
                                }
                            }
                        }
                    }
                    else {
                        System.debug('Invalid format for reserved String in key ' + key);
                    }
                }
                //$$ denotes function call used to fill in a String
                if (valueString.contains('$$')) {
                    String mailingOrBilling = valueString.substringBefore('|');
                    String fullString = valueString.subStringBetween('$$');
                    String controllerToReference = fullString.subStringBefore('.');
                    String functionToCall = fullString.subStringAfter('.');
                    Type classType = Type.forName(controllerToReference);
                    Callable callableInstance = (Callable)classType.newInstance();
                    Map<String, Object> args = new Map<String, Object>();
                    args.put('object', currentSObject);
                    args.put('mailingOrBilling', mailingOrBilling);
                    //Payload Sub Key allows access to inner JSON objects
                    if (payload.get(payloadSubKey) != null) {
                        Map<String, Object> payloadSubMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(payload.get(payloadSubKey)));
                        args.put('data', payloadSubMap.get(key));
                    } 
                    else {
                        args.put('data', String.valueOf(payload.get(key)));
                    }
                    currentSObject = (SObject)callableInstance.call(functionToCall, args);
                    //Handle any Inner Results available
                    for (Integer i = 0; i < payloadSubObjects.size(); i++) {
                        if (innerResults.size() > innerResultsIndex + i) {
                            args.put('object', innerResults[innerResultsIndex + i]);
                            innerResults[innerResultsIndex + i] = (SObject)callableInstance.call(functionToCall, args);
                        }
                    }
                    continue;
                }
                //# denotes string literal
                if (key.contains('`')) {
                    currentSObject.put(valueString, key.substringBetween('`'));
                }
                else {
                    //Check if we have to parse an inner JSON object
                    if (payload.get(payloadSubKey) != null) {
                        //Handle Payload Array
                        String payloadSubValue = JSON.serialize(payload.get(payloadSubKey));
                        if (payloadSubObjects.size() > 0) {
                            //Match the keys between JSON Schema and Payload, and add matched values to the SObject
                            System.debug(payload.get(payloadSubKey));
                            System.debug(payloadSubObjects);
                            for (Integer i = 0; i < payloadSubObjects.size(); i++) {
                                Boolean keysMatched = false;
                                Map<String, Object> payloadSubMap = (Map<String, Object>)payloadSubObjects[i];
                                for (String innerKey : payloadSubMap.keySet()) {
                                    if (key == innerKey) {
                                        innerResults[innerResultsIndex + i].put(valueString, payloadSubMap.get(innerKey));
                                        keysMatched = true;
                                    }
                                }
                                if (keysMatched) {
                                    addedSObjects = true;
                                }
                            }
                        }
                        //Handle Payload Object
                        else if (payloadSubValue.contains('{')) {
                            Map<String, Object> payloadSubMap = (Map<String, Object>)JSON.deserializeUntyped(payloadSubValue);
                            for (String subKey : payloadSubMap.keySet()) {
                                currentSObject.put(valueString, payloadSubMap.get(subKey));
                            }
                        }
                        //Handle basic Payload Key/Value pair
                        else {
                            payloadValue = payloadSubValue;
                        }
                    }
                    //No inner JSON object - Just grab the String value from the Payload
                    else {
                        payloadValue = String.valueOf(payload.get(key));
                    }
                   
                    if (payloadValue != null) {
                        currentSObject.put(valueString, payloadValue);
                    }
                }
            }

            //Assume value is an inner JSON Object and call method recursively
            else {
                keyValueHierarchy.put(key, value);
                //Parse array to instantiate subObjects 
                List<Object> newPayloadSubObjects = new List<Object>();
                if (payload.get(key) != null) {
                    String payloadSubValue = JSON.serialize(payload.get(key));
                    if (payloadSubValue.contains('[')) {
                        String innerJSON = '{ ' + payloadSubValue + ' }';
                        newPayloadSubObjects = (List<Object>)JSON.deserializeUntyped(payloadSubValue.replace('(', '[').replace(')', ']'));
                        for (Object payloadSubObject : newPayloadSubObjects) {
                            innerResults.add(focusSObject.clone());
                        }
                    }
                }
                iterateJSON((Map<String, Object>)value, payload, focusSObject, results, key, newPayloadSubObjects); 
            }
        }

        //Add finalized subobject or subobject list to the results 
        if (addedSObjects) {
            results.addAll(innerResults);
            innerResultsIndex += innerResults.size();
        }
        if (!addedSObjects) {
            results.add(currentSObject); 
        }
        return results;
    }
}