@IsTest
public with sharing class AccountDataFactory {

    private static Integer index = 1;
    private static final String BASE_NAME = 'Location Branch';

    private static Id locationRecordTypeId {
        get {
            if (locationRecordTypeId == null) {
                locationRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Location')
                    ?.getRecordTypeId();
            }
            return locationRecordTypeId;
        }
        set;
    }

    /**
     * Builds a single Account record in-memory (No DML) for fast unit testing.
     */
    public static Account buildAccount() {
        return buildAccount(new Map<String, Object>());
    }

    /**
     * Builds a single Account record in-memory with custom field overrides.
     */
    public static Account buildAccount(Map<String, Object> fieldOverrides) {
        Account record = new Account(
            Name = 'Test ' + BASE_NAME + ' ' + index,
            RecordTypeId = locationRecordTypeId,
            Active__c = true,
            ShippingStreet = '123 High Street',
            ShippingCity = 'London',
            ShippingPostalCode = 'EC1A 1BB',
            ShippingCountry = 'United Kingdom',
            ShippingLatitude = 51.5171,
            ShippingLongitude = -0.1062,
            Phone = '020 7946 000' + Math.mod(index, 10)
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Inserts a single Account record into the database.
     */
    public static Account createAccount() {
        return createAccount(new Map<String, Object>());
    }

    /**
     * Inserts a single Account record into the database with custom field overrides.
     */
    public static Account createAccount(Map<String, Object> fieldOverrides) {
        Account record = buildAccount(fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Builds multiple Account records in-memory (No DML).
     */
    public static List<Account> buildAccountList(Integer count) {
        List<Account> records = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            records.add(buildAccount());
        }
        return records;
    }

    /**
     * Inserts multiple Account records in bulk into the database.
     */
    public static List<Account> createAccountList(Integer count) {
        List<Account> records = buildAccountList(count);
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
