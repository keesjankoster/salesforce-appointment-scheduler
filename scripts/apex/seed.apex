/**
 * 🧦 Hob Test Data Seeder — Salesforce Appointment Scheduler
 * Seeds realistic branch locations, staff, customers, service types, schedules, and appointments.
 */
System.debug('🧦 Hob is planting realistic Appointment Scheduler data...');

// 0. Query Record Types
Id locationRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Location')?.getRecordTypeId();
Id customerRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Customer')?.getRecordTypeId();
Id staffRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Location_Staff')?.getRecordTypeId();

// 1. Branch Locations (Accounts with standard ShippingAddress compound geocodes)
List<Account> branches = new List<Account>{
    new Account(
        Name = 'Central London Branch',
        RecordTypeId = locationRtId,
        Active__c = true,
        Phone = '020 7946 0001',
        ShippingStreet = '100 Cheapside',
        ShippingCity = 'London',
        ShippingPostalCode = 'EC2V 6DN',
        ShippingCountry = 'United Kingdom',
        ShippingLatitude = 51.5142,
        ShippingLongitude = -0.0931
    ),
    new Account(
        Name = 'West End Branch',
        RecordTypeId = locationRtId,
        Active__c = true,
        Phone = '020 7946 0002',
        ShippingStreet = '45 Oxford Street',
        ShippingCity = 'London',
        ShippingPostalCode = 'W1D 2DZ',
        ShippingCountry = 'United Kingdom',
        ShippingLatitude = 51.5158,
        ShippingLongitude = -0.1332
    ),
    new Account(
        Name = 'Kensington Branch',
        RecordTypeId = locationRtId,
        Active__c = true,
        Phone = '020 7946 0003',
        ShippingStreet = '12 Exhibition Road',
        ShippingCity = 'London',
        ShippingPostalCode = 'SW7 2HE',
        ShippingCountry = 'United Kingdom',
        ShippingLatitude = 51.4988,
        ShippingLongitude = -0.1749
    )
};
insert branches;
System.debug('✔ Seeded ' + branches.size() + ' Branch Locations.');

// 2. Location Staff (Contacts linked to Branch Accounts)
List<Contact> staff = new List<Contact>{
    new Contact(
        FirstName = 'Alice',
        LastName = 'Smith',
        RecordTypeId = staffRtId,
        AccountId = branches[0].Id,
        Email = 'alice.smith@example.com',
        Phone = '020 7946 0101'
    ),
    new Contact(
        FirstName = 'Bob',
        LastName = 'Jones',
        RecordTypeId = staffRtId,
        AccountId = branches[1].Id,
        Email = 'bob.jones@example.com',
        Phone = '020 7946 0102'
    ),
    new Contact(
        FirstName = 'Charlie',
        LastName = 'Brown',
        RecordTypeId = staffRtId,
        AccountId = branches[2].Id,
        Email = 'charlie.brown@example.com',
        Phone = '020 7946 0103'
    )
};
insert staff;
System.debug('✔ Seeded ' + staff.size() + ' Location Staff members.');

// 3. Customers (Contacts with home MailingAddress)
List<Contact> customers = new List<Contact>{
    new Contact(
        FirstName = 'David',
        LastName = 'Miller',
        RecordTypeId = customerRtId,
        Email = 'david.miller@customer.example.com',
        Phone = '07700 900123',
        MailingStreet = '10 Downing Street',
        MailingCity = 'London',
        MailingPostalCode = 'SW1A 2AA',
        MailingCountry = 'United Kingdom',
        MailingLatitude = 51.5034,
        MailingLongitude = -0.1276
    ),
    new Contact(
        FirstName = 'Emma',
        LastName = 'Watson',
        RecordTypeId = customerRtId,
        Email = 'emma.watson@customer.example.com',
        Phone = '07700 900456',
        MailingStreet = '221B Baker Street',
        MailingCity = 'London',
        MailingPostalCode = 'NW1 6XE',
        MailingCountry = 'United Kingdom',
        MailingLatitude = 51.5237,
        MailingLongitude = -0.1585
    )
};
insert customers;
System.debug('✔ Seeded ' + customers.size() + ' Customers.');

// 4. Service Types
List<Service_Type__c> serviceTypes = new List<Service_Type__c>{
    new Service_Type__c(
        Name = 'Initial Consultation',
        Duration_Minutes__c = 30,
        Active__c = true,
        Description__c = '30-minute introductory discovery session and requirement review.'
    ),
    new Service_Type__c(
        Name = 'Standard Service',
        Duration_Minutes__c = 60,
        Active__c = true,
        Description__c = 'Standard 60-minute in-depth service and equipment tune-up.'
    ),
    new Service_Type__c(
        Name = 'Comprehensive Inspection',
        Duration_Minutes__c = 120,
        Active__c = true,
        Description__c = 'Full multi-point diagnostics, safety testing, and detailed reporting.'
    )
};
insert serviceTypes;
System.debug('✔ Seeded ' + serviceTypes.size() + ' Service Types.');

// 5. Staff Qualifications (Staff_Service_Type__c junction)
List<Staff_Service_Type__c> qualifications = new List<Staff_Service_Type__c>{
    // Alice does all services
    new Staff_Service_Type__c(Name = 'Alice - Consultation', Staff__c = staff[0].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Alice - Standard', Staff__c = staff[0].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Alice - Comprehensive', Staff__c = staff[0].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true),
    // Bob does Consultation & Standard
    new Staff_Service_Type__c(Name = 'Bob - Consultation', Staff__c = staff[1].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Bob - Standard', Staff__c = staff[1].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    // Charlie does Standard & Comprehensive
    new Staff_Service_Type__c(Name = 'Charlie - Standard', Staff__c = staff[2].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Charlie - Comprehensive', Staff__c = staff[2].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true)
};
insert qualifications;
System.debug('✔ Seeded ' + qualifications.size() + ' Staff Qualifications.');

// 6. Staff Working Hours (Monday through Friday 09:00 - 17:00)
List<String> workDays = new List<String>{ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' };
List<Staff_Working_Hours__c> shifts = new List<Staff_Working_Hours__c>();

for (Contact s : staff) {
    for (String day : workDays) {
        shifts.add(new Staff_Working_Hours__c(
            Name = s.FirstName + ' - ' + day,
            Staff__c = s.Id,
            Day_of_Week__c = day,
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Active__c = true
        ));
    }
}
insert shifts;
System.debug('✔ Seeded ' + shifts.size() + ' Staff Working Hour shifts.');

// 7. Starter Appointment
Date tomorrow = Date.today().addDays(1);
DateTime aptStart = DateTime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0));
DateTime aptEnd = aptStart.addMinutes(60);

Appointment__c sampleApt = new Appointment__c(
    Customer__c = customers[0].Id,
    Location__c = branches[0].Id,
    Staff__c = staff[0].Id,
    Service_Type__c = serviceTypes[1].Id,
    Start_Time__c = aptStart,
    End_Time__c = aptEnd,
    Status__c = 'Scheduled',
    Notes__c = 'Customer requested early morning slot at Central London.'
);
insert sampleApt;
System.debug('✔ Seeded Starter Appointment: ' + sampleApt.Id);

System.debug('🧦 Seeding complete! All appointment scheduler entities are live.');
