@IsTest
private class AppointmentServiceTest {

    @TestSetup
    static void setupTestData() {
        Account branch = AccountDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Bristol Hub' });
        Contact customer1 = ContactDataFactory.createContact(new Map<String, Object>{ 'FirstName' => 'Clara', 'LastName' => 'Oswald' });
        Contact customer2 = ContactDataFactory.createContact(new Map<String, Object>{ 'FirstName' => 'Amy', 'LastName' => 'Pond' });
        Contact staff = ContactDataFactory.createStaffContact(branch.Id, new Map<String, Object>{ 'FirstName' => 'Rory', 'LastName' => 'Williams' });
        Service_Type__c service = Service_TypeDataFactory.createService_Type(new Map<String, Object>{ 'Name' => 'Standard Service', 'Duration_Minutes__c' => 60 });
        Staff_Service_TypeDataFactory.createStaffServiceType(staff.Id, service.Id, null);
    }

    @IsTest
    static void testBookAppointmentSuccess() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Oswald' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Williams' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(2);
        DateTime endTime = startTime.addHours(1);

        Test.startTest();
        Appointment__c booked = AppointmentService.bookAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            startTime,
            endTime,
            'Customer notes here'
        );
        Test.stopTest();

        Assert.isNotNull(booked.Id, 'Appointment should be inserted');
        Assert.areEqual('Scheduled', booked.Status__c);
        Assert.areEqual('Clara Oswald', booked.Customer__r.Name);
        Assert.areEqual('Bristol Hub', booked.Location__r.Name);
        Assert.areEqual('Rory Williams', booked.Staff__r.Name);
    }

    @IsTest
    static void testStaffDoubleBookingPrevented() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer1 = [SELECT Id FROM Contact WHERE LastName = 'Oswald' LIMIT 1];
        Contact customer2 = [SELECT Id FROM Contact WHERE LastName = 'Pond' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Williams' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(3);
        DateTime endTime = startTime.addHours(1);

        // First booking succeeds
        AppointmentService.bookAppointment(
            customer1.Id,
            branch.Id,
            staff.Id,
            service.Id,
            startTime,
            endTime,
            'First booking'
        );

        Boolean conflictCaught = false;

        Test.startTest();
        try {
            // Second booking for customer2 with SAME staff and overlapping time
            AppointmentService.bookAppointment(
                customer2.Id,
                branch.Id,
                staff.Id,
                service.Id,
                startTime.addMinutes(30), // starts mid-way through first booking!
                endTime.addMinutes(30),
                'Conflicting booking'
            );
        } catch (AppointmentService.AppointmentBookingException ex) {
            conflictCaught = true;
            Assert.isTrue(ex.getMessage().contains('conflict'), 'Expected conflict message: ' + ex.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(conflictCaught, 'Staff double-booking must be blocked by AppointmentBookingException');
    }

    @IsTest
    static void testCustomerDoubleBookingPrevented() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Oswald' LIMIT 1];
        Contact staff1 = [SELECT Id FROM Contact WHERE LastName = 'Williams' LIMIT 1];

        // Create second staff member
        Contact staff2 = ContactDataFactory.createStaffContact(branch.Id, new Map<String, Object>{ 'FirstName' => 'River', 'LastName' => 'Song' });
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];
        Staff_Service_TypeDataFactory.createStaffServiceType(staff2.Id, service.Id, null);

        DateTime startTime = DateTime.now().addDays(4);
        DateTime endTime = startTime.addHours(1);

        // Customer books with staff1
        AppointmentService.bookAppointment(
            customer.Id,
            branch.Id,
            staff1.Id,
            service.Id,
            startTime,
            endTime,
            'First customer booking'
        );

        Boolean customerConflictCaught = false;

        Test.startTest();
        try {
            // Customer attempts to book SAME time slot with staff2
            AppointmentService.bookAppointment(
                customer.Id,
                branch.Id,
                staff2.Id,
                service.Id,
                startTime,
                endTime,
                'Simultaneous customer booking'
            );
        } catch (AppointmentService.AppointmentBookingException ex) {
            customerConflictCaught = true;
            Assert.isTrue(ex.getMessage().contains('customer already has an appointment'), 'Expected customer double-booking message');
        }
        Test.stopTest();

        Assert.isTrue(customerConflictCaught, 'Customer cannot be booked in two appointments at the same time');
    }

    @IsTest
    static void testCancelAppointment() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Oswald' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Williams' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(5);
        DateTime endTime = startTime.addHours(1);

        Appointment__c booked = AppointmentService.bookAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            startTime,
            endTime,
            'Initial booking'
        );

        Test.startTest();
        Appointment__c cancelled = AppointmentService.cancelAppointment(booked.Id, 'Client requested postponement');
        Test.stopTest();

        Assert.areEqual('Cancelled', cancelled.Status__c);
        Assert.isTrue(cancelled.Notes__c.contains('Client requested postponement'));
    }

    @IsTest
    static void testInvalidTimeThrowsException() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Oswald' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Williams' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(2);
        DateTime endTime = startTime.addHours(-1); // End is BEFORE start!

        Boolean caught = false;
        try {
            AppointmentService.bookAppointment(customer.Id, branch.Id, staff.Id, service.Id, startTime, endTime, null);
        } catch (AppointmentService.AppointmentBookingException ex) {
            caught = true;
        }
        Assert.isTrue(caught, 'End time before start time should throw exception');
    }
}
