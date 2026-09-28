public with sharing class AvailabilityService {

    public class AvailabilityServiceException extends Exception {}

    public class TimeSlot implements Comparable {
        @AuraEnabled public String slotKey { get; set; }
        @AuraEnabled public String timeDisplay { get; set; }
        @AuraEnabled public DateTime startTime { get; set; }
        @AuraEnabled public DateTime endTime { get; set; }
        @AuraEnabled public Id staffId { get; set; }
        @AuraEnabled public String staffName { get; set; }
        @AuraEnabled public Boolean isAvailable { get; set; }

        public Integer compareTo(Object compareTo) {
            TimeSlot other = (TimeSlot) compareTo;
            if (this.startTime == other.startTime) return 0;
            return this.startTime < other.startTime ? -1 : 1;
        }
    }

    /**
     * Retrieves all active service types for selection in the booking wizard.
     */
    @AuraEnabled(cacheable=true)
    public static List<Service_Type__c> getActiveServiceTypes() {
        return [
            SELECT Id, Name, Duration_Minutes__c, Description__c
            FROM Service_Type__c
            WHERE Active__c = true
            ORDER BY Duration_Minutes__c ASC, Name ASC
        ];
    }

    /**
     * Calculates available appointment time slots at a branch location for a given service and date.
     */
    @AuraEnabled(cacheable=true)
    public static List<TimeSlot> getAvailableSlots(Id locationId, Id serviceTypeId, Date targetDate) {
        if (locationId == null || serviceTypeId == null || targetDate == null) {
            throw new AvailabilityServiceException('Location, Service Type, and Target Date are all required.');
        }

        // 1. Get service duration
        List<Service_Type__c> services = [
            SELECT Id, Name, Duration_Minutes__c
            FROM Service_Type__c
            WHERE Id = :serviceTypeId
            LIMIT 1
        ];

        if (services.isEmpty() || services[0].Duration_Minutes__c == null) {
            throw new AvailabilityServiceException('Invalid Service Type or missing duration.');
        }

        Integer durationMinutes = Integer.valueOf(services[0].Duration_Minutes__c);

        // 2. Identify Day of Week
        DateTime sampleDt = DateTime.newInstance(targetDate, Time.newInstance(12, 0, 0, 0));
        String dayOfWeek = sampleDt.format('EEEE'); // e.g. "Monday"

        // 3. Find qualified staff members at this branch
        List<Staff_Service_Type__c> qualifications = [
            SELECT Staff__c, Staff__r.Name
            FROM Staff_Service_Type__c
            WHERE Service_Type__c = :serviceTypeId
              AND Active__c = true
              AND Staff__r.AccountId = :locationId
        ];

        if (qualifications.isEmpty()) {
            return new List<TimeSlot>();
        }

        Map<Id, String> staffNameMap = new Map<Id, String>();
        for (Staff_Service_Type__c q : qualifications) {
            staffNameMap.put(q.Staff__c, q.Staff__r.Name);
        }

        Set<Id> staffIds = staffNameMap.keySet();

        // 4. Query staff working shifts for this day of week
        List<Staff_Working_Hours__c> shifts = [
            SELECT Staff__c, Day_of_Week__c, Start_Time__c, End_Time__c
            FROM Staff_Working_Hours__c
            WHERE Staff__c IN :staffIds
              AND Day_of_Week__c = :dayOfWeek
              AND Active__c = true
        ];

        if (shifts.isEmpty()) {
            return new List<TimeSlot>();
        }

        // 5. Query existing appointments on targetDate
        DateTime dayStart = DateTime.newInstance(targetDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = dayStart.addDays(1);

        List<Appointment__c> existingBookings = [
            SELECT Id, Staff__c, Start_Time__c, End_Time__c
            FROM Appointment__c
            WHERE Staff__c IN :staffIds
              AND Status__c != 'Cancelled'
              AND Start_Time__c >= :dayStart
              AND Start_Time__c < :dayEnd
        ];

        // Map Staff Id -> List of existing appointments
        Map<Id, List<Appointment__c>> staffBookingsMap = new Map<Id, List<Appointment__c>>();
        for (Appointment__c apt : existingBookings) {
            if (!staffBookingsMap.containsKey(apt.Staff__c)) {
                staffBookingsMap.put(apt.Staff__c, new List<Appointment__c>());
            }
            staffBookingsMap.get(apt.Staff__c).add(apt);
        }

        // 6. Generate candidate slots and evaluate conflicts
        List<TimeSlot> availableSlots = new List<TimeSlot>();
        Set<String> uniqueSlotSignatures = new Set<String>();

        for (Staff_Working_Hours__c shift : shifts) {
            Id staffId = shift.Staff__c;
            String staffName = staffNameMap.get(staffId);
            List<Appointment__c> staffBookings = staffBookingsMap.containsKey(staffId)
                ? staffBookingsMap.get(staffId)
                : new List<Appointment__c>();

            Time shiftStartTime = shift.Start_Time__c;
            Time shiftEndTime = shift.End_Time__c;

            if (shiftStartTime == null || shiftEndTime == null) {
                continue;
            }

            DateTime slotStart = DateTime.newInstance(targetDate, shiftStartTime);
            DateTime shiftEndDt = DateTime.newInstance(targetDate, shiftEndTime);

            while (slotStart.addMinutes(durationMinutes) <= shiftEndDt) {
                DateTime slotEnd = slotStart.addMinutes(durationMinutes);

                Boolean hasConflict = false;
                for (Appointment__c booking : staffBookings) {
                    // Overlap logic: slotStart < bookingEnd AND slotEnd > bookingStart
                    if (slotStart < booking.End_Time__c && slotEnd > booking.Start_Time__c) {
                        hasConflict = true;
                        break;
                    }
                }

                if (!hasConflict) {
                    String signature = slotStart.format('HH:mm') + '-' + slotEnd.format('HH:mm') + '-' + staffId;
                    if (!uniqueSlotSignatures.contains(signature)) {
                        uniqueSlotSignatures.add(signature);

                        TimeSlot slot = new TimeSlot();
                        slot.slotKey = slotStart.format('yyyy-MM-dd\'T\'HH:mm:ss');
                        slot.timeDisplay = slotStart.format('HH:mm') + ' - ' + slotEnd.format('HH:mm');
                        slot.startTime = slotStart;
                        slot.endTime = slotEnd;
                        slot.staffId = staffId;
                        slot.staffName = staffName;
                        slot.isAvailable = true;

                        availableSlots.add(slot);
                    }
                }

                slotStart = slotStart.addMinutes(durationMinutes);
            }
        }

        availableSlots.sort();
        return availableSlots;
    }
}
