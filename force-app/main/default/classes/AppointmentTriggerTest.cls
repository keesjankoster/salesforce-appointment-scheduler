@IsTest
private class AppointmentTriggerTest {

    @TestSetup
    static void setupTestData() {
        Account branch = AccountDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Oxford Branch' });
        Contact customer = ContactDataFactory.createContact(new Map<String, Object>{
            'FirstName' => 'Rose',
            'LastName' => 'Tyler',
            'Email' => 'rose.tyler@example.com'
        });
        Contact staff = ContactDataFactory.createStaffContact(branch.Id, new Map<String, Object>{
            'FirstName' => 'Jack',
            'LastName' => 'Harkness',
            'Email' => 'jack.harkness@branch.example.com'
        });
        Service_Type__c service = Service_TypeDataFactory.createService_Type(new Map<String, Object>{
            'Name' => 'Standard Inspection',
            'Duration_Minutes__c' => 60
        });
        Staff_Service_TypeDataFactory.createStaffServiceType(staff.Id, service.Id, null);
    }

    @IsTest
    static void testTaskCreatedOnAppointmentInsert() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Tyler' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Harkness' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(3);
        DateTime endTime = startTime.addHours(1);

        Test.startTest();
        Appointment__c apt = AppointmentDataFactory.createAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            startTime,
            endTime,
            new Map<String, Object>{ 'Notes__c' => 'Test notes for staff task' }
        );
        Test.stopTest();

        // Verify standard Task creation
        List<Task> createdTasks = [
            SELECT Id, WhatId, WhoId, Subject, ActivityDate, Status, Priority, Description
            FROM Task
            WHERE WhatId = :apt.Id
        ];

        Assert.areEqual(1, createdTasks.size(), 'A follow-up task should be created for the appointment');
        Assert.areEqual(staff.Id, createdTasks[0].WhoId, 'Task WhoId should be the assigned Staff Contact');
        Assert.isTrue(createdTasks[0].Subject.contains('Standard Inspection'), 'Task subject should include service name');
        Assert.areEqual('Not Started', createdTasks[0].Status);
        Assert.isTrue(createdTasks[0].Description.contains('Rose Tyler'), 'Task description should reference customer');
    }

    @IsTest
    static void testCancellationClosesOpenTask() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Tyler' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Harkness' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(4);
        DateTime endTime = startTime.addHours(1);

        Appointment__c apt = AppointmentDataFactory.createAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            startTime,
            endTime,
            null
        );

        Test.startTest();
        apt.Status__c = 'Cancelled';
        update apt;
        Test.stopTest();

        // Verify task updated
        Task closedTask = [
            SELECT Id, Status, Subject
            FROM Task
            WHERE WhatId = :apt.Id
            LIMIT 1
        ];

        Assert.areEqual('Completed', closedTask.Status, 'Task should be marked Completed when appointment is cancelled');
        Assert.isTrue(closedTask.Subject.startsWith('[CANCELLED]'), 'Task subject should be prefixed with [CANCELLED]');
    }

    @IsTest
    static void testDeleteCompletedAppointmentPrevented() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Tyler' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Harkness' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        DateTime startTime = DateTime.now().addDays(-2);
        DateTime endTime = startTime.addHours(1);

        Appointment__c apt = AppointmentDataFactory.createAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            startTime,
            endTime,
            new Map<String, Object>{ 'Status__c' => 'Completed' }
        );

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            delete apt;
        } catch (DmlException ex) {
            exceptionThrown = true;
            Assert.isTrue(ex.getMessage().contains('Completed appointments cannot be deleted'), 'Expected delete restriction error');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Deleting a completed appointment must throw a DML exception');
    }

    @IsTest
    static void testDefaultStatusEnforced() {
        Account branch = [SELECT Id FROM Account LIMIT 1];
        Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Tyler' LIMIT 1];
        Contact staff = [SELECT Id FROM Contact WHERE LastName = 'Harkness' LIMIT 1];
        Service_Type__c service = [SELECT Id FROM Service_Type__c LIMIT 1];

        Appointment__c apt = AppointmentDataFactory.buildAppointment(
            customer.Id,
            branch.Id,
            staff.Id,
            service.Id,
            DateTime.now().addDays(1),
            DateTime.now().addDays(1).addHours(1),
            new Map<String, Object>{ 'Status__c' => null }
        );

        Test.startTest();
        insert apt;
        Test.stopTest();

        Appointment__c insertedApt = [SELECT Id, Status__c FROM Appointment__c WHERE Id = :apt.Id];
        Assert.areEqual('Scheduled', insertedApt.Status__c, 'Null status should default to Scheduled');
    }
}
