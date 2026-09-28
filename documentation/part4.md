# Part 4: High-Velocity TDD — Companion Test Scaffolding with Hob

> *Accelerating Apex domain logic and test-driven development using companion test scaffolding, concurrency locking, and native distance math.*

---

## Introduction: The Apex TDD Friction Point

Test-Driven Development (TDD) is widely acknowledged as the gold standard for software reliability. In theory, developers should write tests first, define method contracts, and iterate until tests pass.

In reality, Salesforce development often discourages TDD because of file-management ceremony:
* To create a single service class and test, you must create four separate files (`MyService.cls`, `MyService.cls-meta.xml`, `MyServiceTest.cls`, `MyServiceTest.cls-meta.xml`).
* You must configure API versions, write `@IsTest`, scaffold `@TestSetup`, import assertion classes, and set up boilerplate.
* Because of this friction, tests are frequently treated as a secondary chore written after the code is "finished," resulting in brittle tests that test implementation details rather than business behavior.

In **Step 4** of building the **Salesforce Appointment Scheduler**, we tackle the core business engine using **Hob: The Salesforce House-Elf** (`hob create apex <Name> --with-test`). 

---

## Scaffolding the Service Layer with Hob

With a single flag (`--with-test`), Hob scaffolds both the production Apex class and its companion test class with `@TestSetup` and modern `Assert` boilerplate in place:

```bash
hob create apex CustomerService --with-test
hob create apex LocationService --with-test
hob create apex AvailabilityService --with-test
hob create apex AppointmentService --with-test
```

### The Terminal Output

```
  🧙 Hob — The Salesforce House-Elf 🧦
  "Loyal, quiet, and tireless assistance for your Salesforce Development."

✔ Created Apex class 'CustomerService'
✔ Created companion test class 'CustomerServiceTest'

🧦 Hob's work here is done! Your Apex files are prepared:

  Directory: force-app/main/default/classes
  Class:     CustomerService.cls
  Test:      CustomerServiceTest.cls (with @TestSetup & Assert boilerplate)
```

With zero boilerplate friction, we immediately implemented and tested the four service engines powering the appointment scheduler.

---

## 1. `CustomerService`: Frictionless Identification & Quick-Create

When a customer contacts the scheduling team, operators need to locate their record instantly or register them on the fly.

### Key Capabilities
* **Dynamic Search**: Queries customer contacts using keyword matching across `FirstName`, `LastName`, `Email`, `Phone`, and `MailingPostalCode` while preventing SOQL injection with `String.escapeSingleQuotes()`.
* **RecordType Enforcement**: Queries the schema for the `Customer` Record Type ID to ensure contacts are properly categorized.
* **Quick Registration**: Exposes an `@AuraEnabled` method allowing the LWC frontend wizard to create and immediately return a new customer in a single transaction.

```apex
@AuraEnabled
public static Contact createCustomer(
    String firstName, String lastName, String email, String phone,
    String street, String city, String postalCode, String country,
    Decimal latitude, Decimal longitude
) {
    if (String.isBlank(lastName)) {
        throw new CustomerServiceException('Last name is required to create a customer.');
    }

    Contact customer = new Contact(
        FirstName = firstName,
        LastName = lastName,
        Email = email,
        Phone = phone,
        RecordTypeId = customerRecordTypeId,
        MailingStreet = street,
        MailingCity = city,
        MailingPostalCode = postalCode,
        MailingCountry = country,
        MailingLatitude = latitude,
        MailingLongitude = longitude
    );

    insert customer;
    return getCustomerById(customer.Id);
}
```

---

## 2. `LocationService`: Proximity Ranking & Skill Filtering

Not every branch provides every service. A branch is only eligible if at least one active staff member is certified for the requested `Service_Type__c`.

### Key Capabilities
* **Staff Skill Evaluation**: Filters branches through the `Staff_Service_Type__c` junction, ensuring only branches with certified staff appear in the selection list.
* **Proximity Ranking**: Ranks branches by proximity to the customer's coordinates.
* **Haversine Distance Calculator**: Provides a mathematically sound great-circle distance algorithm (`calculateHaversineDistanceKm`) as a reliable fallback when geocoding data integration rules are inactive in scratch orgs or offline:

```apex
public static Double calculateHaversineDistanceKm(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;

    Double earthRadiusKm = 6371.0;
    Double dLat = toRadians(Double.valueOf(lat2 - lat1));
    Double dLon = toRadians(Double.valueOf(lon2 - lon1));
    Double rLat1 = toRadians(Double.valueOf(lat1));
    Double rLat2 = toRadians(Double.valueOf(lat2));

    Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
               Math.cos(rLat1) * Math.cos(rLat2) *
               Math.sin(dLon / 2) * Math.sin(dLon / 2);
    Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return Math.round((earthRadiusKm * c) * 10.0) / 10.0;
}
```

---

## 3. `AvailabilityService`: Real-Time Slot Calculation & Shift Intelligence

The core scheduling challenge is determining when appointments can take place. Availability cannot be a static table; it must be calculated dynamically.

### The Algorithm
```
1. Fetch Service Duration (e.g., 60 minutes).
2. Determine Day of Week for targetDate (DateTime.format('EEEE')).
3. Identify Qualified Staff at the selected branch.
4. Retrieve Staff Working Hours (Staff_Working_Hours__c) for that day of the week.
5. Retrieve Existing Bookings (Appointment__c) on targetDate for these staff members.
6. Discretize the shift window into slots of durationMinutes.
7. Discard slots that overlap with existing bookings (slotStart < aptEnd && slotEnd > aptStart).
8. Return sorted, non-conflicting TimeSlot objects.
```

By supporting both full-time (Mon–Fri 09:00–17:00) and part-time shift patterns (morning, afternoon, alternate days), the engine accurately reflects real-world staffing.

---

## 4. `AppointmentService`: Concurrency Locking & Double-Booking Protection

In high-concurrency environments, two operators might attempt to book the last remaining slot for the same technician at the same millisecond. Without database locking, both bookings would succeed, creating an embarrassing double-booking.

`AppointmentService` guards against this using Salesforce database row locking (`FOR UPDATE`):

```apex
// Concurrency Lock & Staff Double-Booking Check
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
```

It additionally validates that the customer is not simultaneously booked into another appointment and provides a clean `cancelAppointment` lifecycle method.

---

## Putting Our Step 3 Factories to Work

One of the greatest joys of this architecture is how expressive and clean our unit tests become. Thanks to the test data factories scaffolded in Step 3, our tests contain zero messy SOQL setup or boilerplate DML:

```apex
@TestSetup
static void setupTestData() {
    Account branch = AccountDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Bristol Hub' });
    Contact customer1 = ContactDataFactory.createContact(new Map<String, Object>{ 'FirstName' => 'Clara', 'LastName' => 'Oswald' });
    Contact customer2 = ContactDataFactory.createContact(new Map<String, Object>{ 'FirstName' => 'Amy', 'LastName' => 'Pond' });
    Contact staff = ContactDataFactory.createStaffContact(branch.Id, new Map<String, Object>{ 'FirstName' => 'Rory', 'LastName' => 'Williams' });
    Service_Type__c service = Service_TypeDataFactory.createService_Type(new Map<String, Object>{ 'Name' => 'Standard Service', 'Duration_Minutes__c' => 60 });
    Staff_Service_TypeDataFactory.createStaffServiceType(staff.Id, service.Id, null);
}
```

Unit tests across all four services execute cleanly, providing comprehensive coverage across positive paths, validation errors, and race-condition simulations.

---

## Security: Updating `Appointment_Scheduler_Operator`

To ensure non-admin users can invoke these services from Lightning Experience and LWC components, we updated our permission set ([`Appointment_Scheduler_Operator.permissionset-meta.xml`](force-app/main/default/permissionsets/Appointment_Scheduler_Operator.permissionset-meta.xml)) with explicit `<classAccesses>`:

```xml
    <classAccesses>
        <apexClass>AppointmentService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>AvailabilityService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>CustomerService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>LocationService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
```

---

## DX Verdict & Tool Feedback

### What Shined
1. **The `--with-test` Habit**: Having the CLI generate companion test files automatically encourages writing unit tests alongside domain logic, lowering the activation energy for TDD.
2. **Modern Assert Syntax**: Hob scaffolds test classes with modern `Assert.areEqual()` and `Assert.isTrue()` syntax rather than deprecated `System.assert` calls.

### Opportunities for Hob's Backlog
1. **`hob create apex --service` or `--aura-enabled`**: Adding flags to pre-populate `@AuraEnabled(cacheable=true)` method signatures or standard service exception classes would accelerate service layer scaffolding even further.

---

## What's Next in Part 5

With our core domain services implemented and thoroughly tested, we now turn to automation.

In **Part 5**, we will explore:
* **"Architecture by Default: Separation of Concerns with Hob Triggers"**
* Using `hob create trigger Appointment__c` to scaffold a modern trigger and companion `AppointmentTriggerHandler`.
* Automating confirmation emails to customers and generating native Salesforce `Task` follow-ups for location staff.
