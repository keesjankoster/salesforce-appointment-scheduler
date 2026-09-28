@IsTest
public with sharing class Staff_Working_HoursDataFactory {

    private static Integer index = 1;

    /**
     * Builds a single Staff_Working_Hours__c record in-memory (No DML) for fast unit testing.
     */
    public static Staff_Working_Hours__c buildStaff_Working_Hours() {
        return buildStaff_Working_Hours(new Map<String, Object>());
    }

    /**
     * Builds a single Staff_Working_Hours__c record in-memory with custom field overrides.
     */
    public static Staff_Working_Hours__c buildStaff_Working_Hours(Map<String, Object> fieldOverrides) {
        Staff_Working_Hours__c record = new Staff_Working_Hours__c(
            Name = 'Working Hours ' + index,
            Day_of_Week__c = 'Monday',
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Active__c = true
        );
        index++;
        applyOverrides(record, fieldOverrides);
        return record;
    }

    /**
     * Builds a single Staff_Working_Hours__c record for a specific staff member.
     */
    public static Staff_Working_Hours__c buildWorkingHours(Id staffId, String dayOfWeek, Time startTime, Time endTime, Map<String, Object> fieldOverrides) {
        Map<String, Object> overrides = new Map<String, Object>{
            'Staff__c' => staffId,
            'Day_of_Week__c' => dayOfWeek,
            'Start_Time__c' => startTime,
            'End_Time__c' => endTime
        };
        if (fieldOverrides != null) {
            overrides.putAll(fieldOverrides);
        }
        return buildStaff_Working_Hours(overrides);
    }

    /**
     * Inserts a single Staff_Working_Hours__c record for a specific staff member.
     */
    public static Staff_Working_Hours__c createWorkingHours(Id staffId, String dayOfWeek, Time startTime, Time endTime, Map<String, Object> fieldOverrides) {
        Staff_Working_Hours__c record = buildWorkingHours(staffId, dayOfWeek, startTime, endTime, fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Creates a standard Monday-Friday 09:00 - 17:00 working schedule for a staff member.
     */
    public static List<Staff_Working_Hours__c> createWeeklySchedule(Id staffId) {
        List<String> days = new List<String>{ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' };
        List<Staff_Working_Hours__c> schedule = new List<Staff_Working_Hours__c>();
        for (String day : days) {
            schedule.add(buildWorkingHours(staffId, day, Time.newInstance(9, 0, 0, 0), Time.newInstance(17, 0, 0, 0), null));
        }
        insert schedule;
        return schedule;
    }

    /**
     * Inserts a single Staff_Working_Hours__c record into the database.
     */
    public static Staff_Working_Hours__c createStaff_Working_Hours() {
        return createStaff_Working_Hours(new Map<String, Object>());
    }

    /**
     * Inserts a single Staff_Working_Hours__c record into the database with custom field overrides.
     */
    public static Staff_Working_Hours__c createStaff_Working_Hours(Map<String, Object> fieldOverrides) {
        Staff_Working_Hours__c record = buildStaff_Working_Hours(fieldOverrides);
        insert record;
        return record;
    }

    /**
     * Builds multiple Staff_Working_Hours__c records in-memory (No DML).
     */
    public static List<Staff_Working_Hours__c> buildStaff_Working_HoursList(Integer count) {
        List<Staff_Working_Hours__c> records = new List<Staff_Working_Hours__c>();
        for (Integer i = 0; i < count; i++) {
            records.add(buildStaff_Working_Hours());
        }
        return records;
    }

    /**
     * Inserts multiple Staff_Working_Hours__c records in bulk into the database.
     */
    public static List<Staff_Working_Hours__c> createStaff_Working_HoursList(Integer count) {
        List<Staff_Working_Hours__c> records = buildStaff_Working_HoursList(count);
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
