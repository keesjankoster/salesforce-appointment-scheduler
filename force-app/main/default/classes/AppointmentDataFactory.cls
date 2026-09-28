@IsTest
public with sharing class AppointmentDataFactory {

    private static Integer index = 1;

    /**
     * Builds a single Appointment__c record in-memory (No DML) for fast unit testing.
     * Note: Appointment__c uses an AutoNumber Name (APT-{0000}), so Name is omitted.
     */
    public static Appointment__c buildAppointment() {
        return buildAppointment(new Map<String, Object>());
    }

    /**
     * Builds a single Appointment__c record in-memory with custom field overrides.
     */
    public static Appointment__c buildAppointment(Map<String, Object> fieldOverrides) {
        DateTime defaultStart = DateTime.now().addDays(1);
        DateTime defaultEnd = defaultStart.addHours(1);

        Appointment__c record = new Appointment__c(
            Start_Time__c = defaultStart,
            End_Time__c = defaultEnd,
            Status__c = 'Scheduled',
            Notes__c = 'Test appointment notes ' + index
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Builds a fully wired Appointment__c record with foreign key relationships in-memory.
     */
    public static Appointment__c buildAppointment(
        Id customerId,
        Id locationId,
        Id staffId,
        Id serviceTypeId,
        DateTime startTime,
        DateTime endTime,
        Map<String, Object> fieldOverrides
    ) {
        Map<String, Object> overrides = new Map<String, Object>{
            'Customer__c' => customerId,
            'Location__c' => locationId,
            'Staff__c' => staffId,
            'Service_Type__c' => serviceTypeId,
            'Start_Time__c' => startTime,
            'End_Time__c' => endTime,
            'Status__c' => 'Scheduled'
        };
        if (fieldOverrides != null) {
            overrides.putAll(fieldOverrides);
        }
        return buildAppointment(overrides);
    }

    /**
     * Inserts a fully wired Appointment__c record into the database.
     */
    public static Appointment__c createAppointment(
        Id customerId,
        Id locationId,
        Id staffId,
        Id serviceTypeId,
        DateTime startTime,
        DateTime endTime,
        Map<String, Object> fieldOverrides
    ) {
        Appointment__c record = buildAppointment(customerId, locationId, staffId, serviceTypeId, startTime, endTime, fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Inserts a single Appointment__c record into the database.
     */
    public static Appointment__c createAppointment() {
        return createAppointment(new Map<String, Object>());
    }

    /**
     * Inserts a single Appointment__c record into the database with custom field overrides.
     */
    public static Appointment__c createAppointment(Map<String, Object> fieldOverrides) {
        Appointment__c record = buildAppointment(fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Builds multiple Appointment__c records in-memory (No DML).
     */
    public static List<Appointment__c> buildAppointmentList(Integer count) {
        List<Appointment__c> records = new List<Appointment__c>();
        for (Integer i = 0; i < count; i++) {
            records.add(buildAppointment());
        }
        return records;
    }

    /**
     * Inserts multiple Appointment__c records in bulk into the database.
     */
    public static List<Appointment__c> createAppointmentList(Integer count) {
        List<Appointment__c> records = buildAppointmentList(count);
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
