public with sharing class AppointmentService {

    public class AppointmentBookingException extends Exception {}

    /**
     * Books a service appointment with transactional concurrency protection against double-booking.
     */
    @AuraEnabled
    public static Appointment__c bookAppointment(
        Id customerId,
        Id locationId,
        Id staffId,
        Id serviceTypeId,
        DateTime startTime,
        DateTime endTime,
        String notes
    ) {
        // 1. Validation
        if (customerId == null || locationId == null || staffId == null || serviceTypeId == null) {
            throw new AppointmentBookingException('Customer, Location, Staff, and Service Type are all required.');
        }
        if (startTime == null || endTime == null || startTime >= endTime) {
            throw new AppointmentBookingException('Valid Start Time and End Time (Start < End) are required.');
        }

        // 2. Concurrency Lock & Staff Double-Booking Check
        List<Appointment__c> staffConflicts = [
            SELECT Id, Name, Start_Time__c, End_Time__c
            FROM Appointment__c
            WHERE Staff__c = :staffId
              AND Status__c != 'Cancelled'
              AND Start_Time__c < :endTime
              AND End_Time__c > :startTime
            FOR UPDATE
        ];

        if (!staffConflicts.isEmpty()) {
            throw new AppointmentBookingException('The selected staff member has a scheduling conflict with another appointment.');
        }

        // 3. Customer Double-Booking Check
        List<Appointment__c> customerConflicts = [
            SELECT Id, Name, Start_Time__c, End_Time__c
            FROM Appointment__c
            WHERE Customer__c = :customerId
              AND Status__c != 'Cancelled'
              AND Start_Time__c < :endTime
              AND End_Time__c > :startTime
        ];

        if (!customerConflicts.isEmpty()) {
            throw new AppointmentBookingException('The customer already has an appointment booked during this time window.');
        }

        // 4. Create and Insert Appointment
        Appointment__c apt = new Appointment__c(
            Customer__c = customerId,
            Location__c = locationId,
            Staff__c = staffId,
            Service_Type__c = serviceTypeId,
            Start_Time__c = startTime,
            End_Time__c = endTime,
            Status__c = 'Scheduled',
            Notes__c = notes
        );

        insert apt;

        return getAppointmentById(apt.Id);
    }

    /**
     * Cancels an existing appointment.
     */
    @AuraEnabled
    public static Appointment__c cancelAppointment(Id appointmentId, String cancellationReason) {
        if (appointmentId == null) {
            throw new AppointmentBookingException('Appointment ID must not be null.');
        }

        Appointment__c apt = [
            SELECT Id, Status__c, Notes__c
            FROM Appointment__c
            WHERE Id = :appointmentId
            FOR UPDATE
        ];

        apt.Status__c = 'Cancelled';
        if (String.isNotBlank(cancellationReason)) {
            String timestamp = DateTime.now().format('yyyy-MM-dd HH:mm');
            String noteAppend = '\n[Cancelled on ' + timestamp + ']: ' + cancellationReason;
            apt.Notes__c = (apt.Notes__c != null ? apt.Notes__c : '') + noteAppend;
        }

        update apt;

        return getAppointmentById(apt.Id);
    }

    /**
     * Retrieves full appointment details with related entities.
     */
    @AuraEnabled(cacheable=true)
    public static Appointment__c getAppointmentById(Id appointmentId) {
        if (appointmentId == null) {
            throw new AppointmentBookingException('Appointment ID must not be null.');
        }

        List<Appointment__c> appointments = [
            SELECT Id, Name, Customer__c, Customer__r.Name, Customer__r.Email, Customer__r.Phone,
                   Location__c, Location__r.Name, Location__r.ShippingStreet, Location__r.ShippingCity,
                   Location__r.ShippingPostalCode, Staff__c, Staff__r.Name, Staff__r.Email,
                   Service_Type__c, Service_Type__r.Name, Service_Type__r.Duration_Minutes__c,
                   Start_Time__c, End_Time__c, Status__c, Notes__c, CreatedDate
            FROM Appointment__c
            WHERE Id = :appointmentId
            LIMIT 1
        ];

        if (appointments.isEmpty()) {
            throw new AppointmentBookingException('Appointment not found with ID: ' + appointmentId);
        }

        return appointments[0];
    }
}
