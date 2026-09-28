@IsTest
private class AvailabilityServiceTest {

    // Helper to calculate the next Monday
    private static Date getNextMonday() {
        Date today = Date.today();
        // Start looking from tomorrow
        Date candidate = today.addDays(1);
        while (DateTime.newInstance(candidate, Time.newInstance(12, 0, 0, 0)).format('EEEE') != 'Monday') {
            candidate = candidate.addDays(1);
        }
        return candidate;
    }

    @TestSetup
    static void setupTestData() {
        // 1. Branch
        Account branch = AccountDataFactory.createAccount(new Map<String, Object>{
            'Name' => 'Test Hub'
        });

        // 2. Customer
        Contact customer = ContactDataFactory.createContact(new Map<String, Object>{
            'LastName' => 'TestCustomer'
        });

        // 3. Staff
        Contact staff = ContactDataFactory.createStaffContact(branch.Id, new Map<String, Object>{
            'FirstName' => 'Sarah',
            'LastName' => 'Tech'
        });

        // 4. Service (60 mins)
        Service_Type__c service = Service_TypeDataFactory.createService_Type(new Map<String, Object>{
            'Name' => 'Standard Diagnostic',
            'Duration_Minutes__c' => 60
        });

        // 5. Qualification
        Staff_Service_TypeDataFactory.createStaffServiceType(staff.Id, service.Id, null);

        // 6. Working shift on Monday 09:00 - 12:00 (3 hours = 3 one-hour slots)
        Staff_Working_HoursDataFactory.createWorkingHours(
            staff.Id,
            'Monday',
            Time.newInstance(9, 0, 0, 0),
            Time.newInstance(12, 0, 0, 0),
            null
        );

        // 7. Existing appointment in middle slot (10:00 - 11:00)
        Date nextMon = getNextMonday();
        DateTime bookingStart = DateTime.newInstance(nextMon, Time.newInstance(10, 0, 0, 0));
        DateTime bookingEnd = bookingStart.addMinutes(60);

        AppointmentDataFactory.createAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            bookingStart,
            bookingEnd,
            null
        );
    }

    @IsTest
    static void testGetAvailableSlotsExcludesBookedTimes() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];
        Date nextMon = getNextMonday();

        Test.startTest();
        List<AvailabilityService.TimeSlot> slots = AvailabilityService.getAvailableSlots(
            branch.Id,
            service.Id,
            nextMon
        );
        Test.stopTest();

        // 09:00-12:00 has 3 potential slots: 09:00-10:00, 10:00-11:00, 11:00-12:00.
        // 10:00-11:00 is booked, so exactly 2 slots should be available.
        Assert.areEqual(2, slots.size(), 'Should have 2 available slots after excluding conflict');
        Assert.areEqual('09:00 - 10:00', slots[0].timeDisplay);
        Assert.areEqual('11:00 - 12:00', slots[1].timeDisplay);
        Assert.isTrue(slots[0].isAvailable);
    }

    @IsTest
    static void testNoShiftsReturnsEmptyList() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        // Sunday has no shifts configured
        Date nextSunday = getNextMonday().addDays(6);

        Test.startTest();
        List<AvailabilityService.TimeSlot> slots = AvailabilityService.getAvailableSlots(
            branch.Id,
            service.Id,
            nextSunday
        );
        Test.stopTest();

        Assert.isTrue(slots.isEmpty(), 'Sunday should return empty slots list');
    }

    @IsTest
    static void testNullArgumentsThrowException() {
        Boolean caught = false;
        try {
            AvailabilityService.getAvailableSlots(null, null, null);
        } catch (AvailabilityService.AvailabilityServiceException ex) {
            caught = true;
        }
        Assert.isTrue(caught, 'Null arguments should throw AvailabilityServiceException');
    }
}
