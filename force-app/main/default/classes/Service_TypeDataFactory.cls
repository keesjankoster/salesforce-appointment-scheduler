@IsTest
public with sharing class Service_TypeDataFactory {

    private static Integer index = 1;
    private static final String BASE_NAME = 'Service Type';

    /**
     * Builds a single Service_Type__c record in-memory (No DML) for fast unit testing.
     */
    public static Service_Type__c buildService_Type() {
        return buildService_Type(new Map<String, Object>());
    }

    /**
     * Builds a single Service_Type__c record in-memory with custom field overrides.
     */
    public static Service_Type__c buildService_Type(Map<String, Object> fieldOverrides) {
        Service_Type__c record = new Service_Type__c(
            Name = BASE_NAME + ' ' + index,
            Duration_Minutes__c = 60,
            Active__c = true,
            Description__c = 'Default service description for ' + BASE_NAME + ' ' + index
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Inserts a single Service_Type__c record into the database.
     */
    public static Service_Type__c createService_Type() {
        return createService_Type(new Map<String, Object>());
    }

    /**
     * Inserts a single Service_Type__c record into the database with custom field overrides.
     */
    public static Service_Type__c createService_Type(Map<String, Object> fieldOverrides) {
        Service_Type__c record = buildService_Type(fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Builds multiple Service_Type__c records in-memory (No DML).
     */
    public static List<Service_Type__c> buildService_TypeList(Integer count) {
        List<Service_Type__c> records = new List<Service_Type__c>();
        for (Integer i = 0; i < count; i++) {
            records.add(buildService_Type());
        }
        return records;
    }

    /**
     * Inserts multiple Service_Type__c records in bulk into the database.
     */
    public static List<Service_Type__c> createService_TypeList(Integer count) {
        List<Service_Type__c> records = buildService_TypeList(count);
        insert records;
        return records;
    }

    private static void applyOverrides(SObject record, Map<String, Object> fieldOverrides) {
        if (fieldOverrides == null || fieldOverrides.isEmpty()) {
            return;
        }
        for (String fieldName : fieldOverrides.keySet()) {
            record.put(fieldName, fieldOverrides.get(fieldName));
        }
    }
}
