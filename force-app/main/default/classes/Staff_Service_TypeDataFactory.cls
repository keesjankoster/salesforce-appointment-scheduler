@IsTest
public with sharing class Staff_Service_TypeDataFactory {

    private static Integer index = 1;

    /**
     * Builds a single Staff_Service_Type__c record in-memory (No DML) for fast unit testing.
     */
    public static Staff_Service_Type__c buildStaff_Service_Type() {
        return buildStaff_Service_Type(new Map<String, Object>());
    }

    /**
     * Builds a single Staff_Service_Type__c record in-memory with custom field overrides.
     */
    public static Staff_Service_Type__c buildStaff_Service_Type(Map<String, Object> fieldOverrides) {
        Staff_Service_Type__c record = new Staff_Service_Type__c(
            Name = 'Staff Service Type ' + index,
            Active__c = true
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Builds a single Staff_Service_Type__c junction record linking staff to a service type.
     */
    public static Staff_Service_Type__c buildStaffServiceType(Id staffId, Id serviceTypeId, Map<String, Object> fieldOverrides) {
        Map<String, Object> overrides = new Map<String, Object>{
            'Staff__c' => staffId,
            'Service_Type__c' => serviceTypeId
        };
        if (fieldOverrides != null) {
            overrides.putAll(fieldOverrides);
        }
        return buildStaff_Service_Type(overrides);
    }

    /**
     * Inserts a single Staff_Service_Type__c junction record linking staff to a service type.
     */
    public static Staff_Service_Type__c createStaffServiceType(Id staffId, Id serviceTypeId, Map<String, Object> fieldOverrides) {
        Staff_Service_Type__c record = buildStaffServiceType(staffId, serviceTypeId, fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Inserts a single Staff_Service_Type__c record into the database.
     */
    public static Staff_Service_Type__c createStaff_Service_Type() {
        return createStaff_Service_Type(new Map<String, Object>());
    }

    /**
     * Inserts a single Staff_Service_Type__c record into the database with custom field overrides.
     */
    public static Staff_Service_Type__c createStaff_Service_Type(Map<String, Object> fieldOverrides) {
        Staff_Service_Type__c record = buildStaff_Service_Type(fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Builds multiple Staff_Service_Type__c records in-memory (No DML).
     */
    public static List<Staff_Service_Type__c> buildStaff_Service_TypeList(Integer count) {
        List<Staff_Service_Type__c> records = new List<Staff_Service_Type__c>();
        for (Integer i = 0; i < count; i++) {
            records.add(buildStaff_Service_Type());
        }
        return records;
    }

    /**
     * Inserts multiple Staff_Service_Type__c records in bulk into the database.
     */
    public static List<Staff_Service_Type__c> createStaff_Service_TypeList(Integer count) {
        List<Staff_Service_Type__c> records = buildStaff_Service_TypeList(count);
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
