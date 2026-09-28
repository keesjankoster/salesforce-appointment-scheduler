@IsTest
public with sharing class ContactDataFactory {

    private static Integer index = 1;

    private static Id customerRecordTypeId {
        get {
            if (customerRecordTypeId == null) {
                customerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                    .get('Customer')
                    ?.getRecordTypeId();
            }
            return customerRecordTypeId;
        }
        set;
    }

    private static Id staffRecordTypeId {
        get {
            if (staffRecordTypeId == null) {
                staffRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                    .get('Location_Staff')
                    ?.getRecordTypeId();
            }
            return staffRecordTypeId;
        }
        set;
    }

    /**
     * Builds a single Contact record in-memory (No DML) for fast unit testing.
     * Defaults to Customer record type.
     */
    public static Contact buildContact() {
        return buildContact(new Map<String, Object>());
    }

    /**
     * Builds a single Contact record in-memory with custom field overrides.
     */
    public static Contact buildContact(Map<String, Object> fieldOverrides) {
        Contact record = new Contact(
            FirstName = 'Test',
            LastName = 'Customer ' + index,
            RecordTypeId = customerRecordTypeId,
            Email = 'customer' + index + '@example.com',
            Phone = '07700 90000' + Math.mod(index, 10),
            MailingStreet = '10 Downing Street',
            MailingCity = 'London',
            MailingPostalCode = 'SW1A 2AA',
            MailingCountry = 'United Kingdom',
            MailingLatitude = 51.5034,
            MailingLongitude = -0.1276
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Builds a Location Staff Contact record in-memory associated with a branch Account.
     */
    public static Contact buildStaffContact(Id branchAccountId, Map<String, Object> fieldOverrides) {
        Contact record = new Contact(
            FirstName = 'Staff',
            LastName = 'Member ' + index,
            RecordTypeId = staffRecordTypeId,
            AccountId = branchAccountId,
            Email = 'staff' + index + '@branch.example.com',
            Phone = '020 7946 011' + Math.mod(index, 10)
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Inserts a Location Staff Contact record associated with a branch Account.
     */
    public static Contact createStaffContact(Id branchAccountId, Map<String, Object> fieldOverrides) {
        Contact record = buildStaffContact(branchAccountId, fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Inserts a single Contact record into the database.
     */
    public static Contact createContact() {
        return createContact(new Map<String, Object>());
    }

    /**
     * Inserts a single Contact record into the database with custom field overrides.
     */
    public static Contact createContact(Map<String, Object> fieldOverrides) {
        Contact record = buildContact(fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Builds multiple Contact records in-memory (No DML).
     */
    public static List<Contact> buildContactList(Integer count) {
        List<Contact> records = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            records.add(buildContact());
        }
        return records;
    }

    /**
     * Inserts multiple Contact records in bulk into the database.
     */
    public static List<Contact> createContactList(Integer count) {
        List<Contact> records = buildContactList(count);
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
