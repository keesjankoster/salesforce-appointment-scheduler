/**
 * 🧦 Hob Test Data Seeder — Salesforce Appointment Scheduler
 * Seeds realistic nationwide branch locations, full-time & part-time staff,
 * regional customers, service catalog, working shifts, and starter appointments.
 */
System.debug('🧦 Hob is planting realistic nationwide Appointment Scheduler data...');

// 0. Query Record Types
Id locationRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Location')?.getRecordTypeId();
Id customerRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Customer')?.getRecordTypeId();
Id staffRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Location_Staff')?.getRecordTypeId();

// 1. Nationwide Branch Locations (London, Birmingham, Manchester, Leeds)
// Leveraging standard Account.ShippingAddress compound geocodes for native SOQL DISTANCE() queries
List<Account> branches = new List<Account>{
    new Account(
        Name = 'London Flagship Branch',
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
        Name = 'Birmingham Colmore Branch',
        RecordTypeId = locationRtId,
        Active__c = true,
        Phone = '0121 496 0001',
        ShippingStreet = '1 Colmore Row',
        ShippingCity = 'Birmingham',
        ShippingPostalCode = 'B3 2QD',
        ShippingCountry = 'United Kingdom',
        ShippingLatitude = 52.4831,
        ShippingLongitude = -1.8998
    ),
    new Account(
        Name = 'Manchester Deansgate Branch',
        RecordTypeId = locationRtId,
        Active__c = true,
        Phone = '0161 496 0001',
        ShippingStreet = '100 Deansgate',
        ShippingCity = 'Manchester',
        ShippingPostalCode = 'M3 2BB',
        ShippingCountry = 'United Kingdom',
        ShippingLatitude = 53.4808,
        ShippingLongitude = -2.2468
    ),
    new Account(
        Name = 'Leeds Park Row Branch',
        RecordTypeId = locationRtId,
        Active__c = true,
        Phone = '0113 496 0001',
        ShippingStreet = '29 Park Row',
        ShippingCity = 'Leeds',
        ShippingPostalCode = 'LS1 5HD',
        ShippingCountry = 'United Kingdom',
        ShippingLatitude = 53.7974,
        ShippingLongitude = -1.5473
    )
};
insert branches;
System.debug('✔ Seeded ' + branches.size() + ' Nationwide Branch Locations.');

// 2. Location Staff (Mix of Full-time and Part-time staff across all branches)
List<Contact> staff = new List<Contact>{
    // London
    new Contact(
        FirstName = 'Alice',
        LastName = 'Smith',
        Title = 'Senior Consultant (Full-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[0].Id,
        Email = 'alice.smith@appointment-scheduler.co.uk',
        Phone = '020 7946 0101'
    ),
    new Contact(
        FirstName = 'David',
        LastName = 'Clarke',
        Title = 'Junior Specialist (Part-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[0].Id,
        Email = 'david.clarke@appointment-scheduler.co.uk',
        Phone = '020 7946 0102'
    ),
    // Birmingham
    new Contact(
        FirstName = 'Bob',
        LastName = 'Jones',
        Title = 'Lead Technician (Full-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[1].Id,
        Email = 'bob.jones@appointment-scheduler.co.uk',
        Phone = '0121 496 0101'
    ),
    new Contact(
        FirstName = 'Priya',
        LastName = 'Patel',
        Title = 'Customer Advisor (Part-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[1].Id,
        Email = 'priya.patel@appointment-scheduler.co.uk',
        Phone = '0121 496 0102'
    ),
    // Manchester
    new Contact(
        FirstName = 'Charlie',
        LastName = 'Brown',
        Title = 'Service Specialist (Full-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[2].Id,
        Email = 'charlie.brown@appointment-scheduler.co.uk',
        Phone = '0161 496 0101'
    ),
    new Contact(
        FirstName = 'Liam',
        LastName = 'Gallagher',
        Title = 'Diagnostic Assistant (Part-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[2].Id,
        Email = 'liam.gallagher@appointment-scheduler.co.uk',
        Phone = '0161 496 0102'
    ),
    // Leeds
    new Contact(
        FirstName = 'Fiona',
        LastName = 'Rhodes',
        Title = 'Branch Manager & Specialist (Full-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[3].Id,
        Email = 'fiona.rhodes@appointment-scheduler.co.uk',
        Phone = '0113 496 0101'
    ),
    new Contact(
        FirstName = 'George',
        LastName = 'Harrison',
        Title = 'Technician (Part-time)',
        RecordTypeId = staffRtId,
        AccountId = branches[3].Id,
        Email = 'george.harrison@appointment-scheduler.co.uk',
        Phone = '0113 496 0102'
    )
};
insert staff;
System.debug('✔ Seeded ' + staff.size() + ' Location Staff members across 4 branches.');

// 3. Regional Customers (Distributed near branch networks)
List<Contact> customers = new List<Contact>{
    new Contact(
        FirstName = 'James',
        LastName = 'Bennett',
        RecordTypeId = customerRtId,
        Email = 'james.bennett@example.co.uk',
        Phone = '07700 900111',
        MailingStreet = '10 Downing Street',
        MailingCity = 'London',
        MailingPostalCode = 'SW1A 2AA',
        MailingCountry = 'United Kingdom',
        MailingLatitude = 51.5034,
        MailingLongitude = -0.1276
    ),
    new Contact(
        FirstName = 'Sophie',
        LastName = 'Taylor',
        RecordTypeId = customerRtId,
        Email = 'sophie.taylor@example.co.uk',
        Phone = '07700 900222',
        MailingStreet = '14 Warwick Road',
        MailingCity = 'Solihull',
        MailingPostalCode = 'B91 3QG',
        MailingCountry = 'United Kingdom',
        MailingLatitude = 52.4128,
        MailingLongitude = -1.7782
    ),
    new Contact(
        FirstName = 'Jack',
        LastName = 'Davies',
        RecordTypeId = customerRtId,
        Email = 'jack.davies@example.co.uk',
        Phone = '07700 900333',
        MailingStreet = '22 The Crescent',
        MailingCity = 'Salford',
        MailingPostalCode = 'M5 4WT',
        MailingCountry = 'United Kingdom',
        MailingLatitude = 53.4839,
        MailingLongitude = -2.2743
    ),
    new Contact(
        FirstName = 'Hannah',
        LastName = 'Walker',
        RecordTypeId = customerRtId,
        Email = 'hannah.walker@example.co.uk',
        Phone = '07700 900444',
        MailingStreet = '5 Moorland Road',
        MailingCity = 'Leeds',
        MailingPostalCode = 'LS6 1AL',
        MailingCountry = 'United Kingdom',
        MailingLatitude = 53.8118,
        MailingLongitude = -1.5642
    )
};
insert customers;
System.debug('✔ Seeded ' + customers.size() + ' Regional Customers.');

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
    // London: Alice (All), David (Consultation & Standard)
    new Staff_Service_Type__c(Name = 'Alice - Consultation', Staff__c = staff[0].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Alice - Standard', Staff__c = staff[0].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Alice - Comprehensive', Staff__c = staff[0].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'David - Consultation', Staff__c = staff[1].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'David - Standard', Staff__c = staff[1].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),

    // Birmingham: Bob (Standard & Comprehensive), Priya (Consultation)
    new Staff_Service_Type__c(Name = 'Bob - Standard', Staff__c = staff[2].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Bob - Comprehensive', Staff__c = staff[2].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Priya - Consultation', Staff__c = staff[3].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),

    // Manchester: Charlie (All), Liam (Standard)
    new Staff_Service_Type__c(Name = 'Charlie - Consultation', Staff__c = staff[4].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Charlie - Standard', Staff__c = staff[4].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Charlie - Comprehensive', Staff__c = staff[4].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Liam - Standard', Staff__c = staff[5].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),

    // Leeds: Fiona (All), George (Standard & Comprehensive)
    new Staff_Service_Type__c(Name = 'Fiona - Consultation', Staff__c = staff[6].Id, Service_Type__c = serviceTypes[0].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Fiona - Standard', Staff__c = staff[6].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'Fiona - Comprehensive', Staff__c = staff[6].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'George - Standard', Staff__c = staff[7].Id, Service_Type__c = serviceTypes[1].Id, Active__c = true),
    new Staff_Service_Type__c(Name = 'George - Comprehensive', Staff__c = staff[7].Id, Service_Type__c = serviceTypes[2].Id, Active__c = true)
};
insert qualifications;
System.debug('✔ Seeded ' + qualifications.size() + ' Staff Qualifications.');

// 6. Staff Working Hours (Realistic Mix of Full-time and Part-time Shifts)
List<Staff_Working_Hours__c> shifts = new List<Staff_Working_Hours__c>();

// Helper method logic for creating shifts
List<String> weekdays = new List<String>{ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' };

// A. FULL-TIME STAFF: Mon-Fri 09:00 - 17:00 (Charlie in Manchester 08:30 - 16:30)
List<Contact> fullTimeStaff = new List<Contact>{ staff[0], staff[2], staff[6] }; // Alice, Bob, Fiona
for (Contact s : fullTimeStaff) {
    for (String day : weekdays) {
        shifts.add(new Staff_Working_Hours__c(
            Name = s.FirstName + ' - ' + day + ' (FT)',
            Staff__c = s.Id,
            Day_of_Week__c = day,
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Active__c = true
        ));
    }
}

// Charlie (Manchester FT - early bird shift 08:30 - 16:30)
for (String day : weekdays) {
    shifts.add(new Staff_Working_Hours__c(
        Name = 'Charlie - ' + day + ' (FT)',
        Staff__c = staff[4].Id,
        Day_of_Week__c = day,
        Start_Time__c = Time.newInstance(8, 30, 0, 0),
        End_Time__c = Time.newInstance(16, 30, 0, 0),
        Active__c = true
    ));
}

// B. PART-TIME STAFF: Diverse schedules and shift patterns

// David (London PT): Mon, Wed, Fri mornings (09:00 - 13:00)
for (String day : new List<String>{ 'Monday', 'Wednesday', 'Friday' }) {
    shifts.add(new Staff_Working_Hours__c(
        Name = 'David - ' + day + ' (PT Morning)',
        Staff__c = staff[1].Id,
        Day_of_Week__c = day,
        Start_Time__c = Time.newInstance(9, 0, 0, 0),
        End_Time__c = Time.newInstance(13, 0, 0, 0),
        Active__c = true
    ));
}

// Priya (Birmingham PT): Tue, Thu full days (09:00 - 17:00)
for (String day : new List<String>{ 'Tuesday', 'Thursday' }) {
    shifts.add(new Staff_Working_Hours__c(
        Name = 'Priya - ' + day + ' (PT Full Day)',
        Staff__c = staff[3].Id,
        Day_of_Week__c = day,
        Start_Time__c = Time.newInstance(9, 0, 0, 0),
        End_Time__c = Time.newInstance(17, 0, 0, 0),
        Active__c = true
    ));
}

// Liam (Manchester PT): Mon, Tue, Wed afternoons (12:30 - 17:00)
for (String day : new List<String>{ 'Monday', 'Tuesday', 'Wednesday' }) {
    shifts.add(new Staff_Working_Hours__c(
        Name = 'Liam - ' + day + ' (PT Afternoon)',
        Staff__c = staff[5].Id,
        Day_of_Week__c = day,
        Start_Time__c = Time.newInstance(12, 30, 0, 0),
        End_Time__c = Time.newInstance(17, 0, 0, 0),
        Active__c = true
    ));
}

// George (Leeds PT): Wed, Thu, Fri mornings (08:30 - 13:30)
for (String day : new List<String>{ 'Wednesday', 'Thursday', 'Friday' }) {
    shifts.add(new Staff_Working_Hours__c(
        Name = 'George - ' + day + ' (PT Morning)',
        Staff__c = staff[7].Id,
        Day_of_Week__c = day,
        Start_Time__c = Time.newInstance(8, 30, 0, 0),
        End_Time__c = Time.newInstance(13, 30, 0, 0),
        Active__c = true
    ));
}

insert shifts;
System.debug('✔ Seeded ' + shifts.size() + ' Staff Working Hour shifts (Full-time & Part-time mix).');

// 7. Starter Appointments (Demonstrating multi-region scheduled bookings)
Date tomorrow = Date.today().addDays(1);
DateTime apt1Start = DateTime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0));
DateTime apt1End = apt1Start.addMinutes(60);

DateTime apt2Start = DateTime.newInstance(tomorrow.addDays(1), Time.newInstance(14, 0, 0, 0));
DateTime apt2End = apt2Start.addMinutes(120);

List<Appointment__c> sampleAppointments = new List<Appointment__c>{
    // London appointment for James with Alice
    new Appointment__c(
        Customer__c = customers[0].Id,
        Location__c = branches[0].Id,
        Staff__c = staff[0].Id,
        Service_Type__c = serviceTypes[1].Id,
        Start_Time__c = apt1Start,
        End_Time__c = apt1End,
        Status__c = 'Scheduled',
        Notes__c = 'Customer requested 10:00 AM slot at London Flagship branch.'
    ),
    // Manchester appointment for Jack with Charlie
    new Appointment__c(
        Customer__c = customers[2].Id,
        Location__c = branches[2].Id,
        Staff__c = staff[4].Id,
        Service_Type__c = serviceTypes[2].Id,
        Start_Time__c = apt2Start,
        End_Time__c = apt2End,
        Status__c = 'Scheduled',
        Notes__c = 'Customer booked Comprehensive Inspection at Manchester Deansgate.'
    )
};
insert sampleAppointments;
System.debug('✔ Seeded ' + sampleAppointments.size() + ' Starter Appointments across regions.');

System.debug('🧦 Seeding complete! Realistic nationwide data with FT/PT staff schedules is live.');
