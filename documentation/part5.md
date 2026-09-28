# Part 5: Architecture by Default — Separation of Concerns with Hob Triggers

> *Eliminating trigger anti-patterns, automating customer confirmation emails, and generating native Salesforce Tasks using scaffolded trigger handlers.*

---

## Introduction: The "God Trigger" Anti-Pattern

Apex triggers are one of the most powerful features on the Salesforce platform, enabling immediate server-side execution whenever records are created, updated, or deleted. 

Unfortunately, triggers are also where code quality most frequently degenerates. Common anti-patterns include:

1. **The 800-Line "God Trigger"**: Writing business logic, queries, and DML directly inside the `.trigger` file. This makes unit testing impossible without triggering full DML transactions and prevents logic reuse across batch jobs or APIs.
2. **Multiple Triggers on a Single Object**: Having `AppointmentBeforeTrigger.trigger` and `AppointmentAfterTrigger.trigger`—or multiple developers creating their own triggers. Salesforce explicitly does **not** guarantee the execution order of multiple triggers on the same object, leading to non-deterministic behavior and intermittent bugs.
3. **Trigger Boilerplate Fatigue**: Writing the mandatory boilerplate for a clean trigger framework (trigger file, trigger handler class, metadata XMLs, `switch on Trigger.operationType` dispatchers) is repetitive, leading developers to cut corners and dump logic directly into the trigger.

In **Step 5** of building the **Salesforce Appointment Scheduler**, we enforce **Architecture by Default** using **Hob: The Salesforce House-Elf** (`hob create trigger`).

---

## Scaffolding the Trigger with Hob

With one command, Hob scaffolds both the logic-less trigger and its companion handler class, pre-configured with complete separation of concerns and modern `System.TriggerOperation` dispatching:

```bash
hob create trigger Appointment__c
```

### The Terminal Output

```
  🧙 Hob — The Salesforce House-Elf 🧦
  "Loyal, quiet, and tireless assistance for your Salesforce Development."

✔ Created Apex trigger 'AppointmentTrigger'
✔ Created TriggerHandler class 'AppointmentTriggerHandler'

🧦 Hob prepared your trigger and handler with clean Separation of Concerns:

  Trigger: force-app/main/default/triggers/AppointmentTrigger.trigger
  Handler: force-app/main/default/classes/AppointmentTriggerHandler.cls
  SObject: Appointment__c
```

### 1. The Logic-less Trigger ([`AppointmentTrigger.trigger`](force-app/main/default/triggers/AppointmentTrigger.trigger))

The generated trigger contains zero business logic. Its sole responsibility is delegating to the handler:

```apex
trigger AppointmentTrigger on Appointment__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    AppointmentTriggerHandler.handleTrigger(
        Trigger.operationType,
        Trigger.new,
        Trigger.oldMap
    );
}
```

### 2. The Handler Dispatcher ([`AppointmentTriggerHandler.cls`](force-app/main/default/classes/AppointmentTriggerHandler.cls))

Hob provides clean routing using Salesforce's `System.TriggerOperation` enum:

```apex
switch on operationType {
    when BEFORE_INSERT { onBeforeInsert(newList); }
    when AFTER_INSERT  { onAfterInsert(newList); }
    when BEFORE_UPDATE { onBeforeUpdate(newList, oldMap); }
    when AFTER_UPDATE  { onAfterUpdate(newList, oldMap); }
    when BEFORE_DELETE { onBeforeDelete(oldMap); }
    when AFTER_DELETE  { onAfterDelete(oldMap); }
    when AFTER_UNDELETE{ onAfterUndelete(newList); }
}
```

---

## Domain Automation in Action

With the trigger framework scaffolded in seconds, we implemented the automated business workflows required by the appointment scheduler:

### 1. Standard Salesforce `Task` Generation (`after insert`)
In line with our architectural principle of **maximizing native Salesforce platform features**, scheduling an appointment automatically creates a standard `Task` for the assigned branch technician:

```apex
Task staffTask = new Task(
    WhatId = apt.Id,              // Linked directly to Appointment__c
    WhoId = apt.Staff__c,         // Assigned to Staff Contact
    Subject = 'Service Appointment: ' + serviceName,
    ActivityDate = appointmentDate,
    Status = 'Not Started',
    Priority = 'Normal',
    Description = 'Upcoming appointment with ' + customerName + ' at ' + locationName
);
tasksToInsert.add(staffTask);
```

Because this is a standard Salesforce `Task`:
* It appears immediately on the technician's Lightning Activity Timeline.
* It respects standard CRM notifications and reminders.
* It links the appointment transaction to the CRM activity history with zero custom UI required.

### 2. Automated Confirmation Emails
Upon insertion of an appointment with `Status__c = 'Scheduled'`, the handler dispatches dual notifications:
* **Customer Confirmation**: Details the service name, scheduled time, branch address, and assigned specialist.
* **Staff Alert**: Informs the technician of the new booking and references their newly created follow-up task.

All email generation includes governor limit checks (`Limits.getEmailInvocations() < Limits.getLimitEmailInvocations()`) to ensure bulk safe execution.

### 3. Lifecycle Automation: Cancellation (`after update`)
When an operator cancels an appointment (`Status__c` changes to `'Cancelled'`):
* Open follow-up `Task` records linked via `WhatId` are automatically marked as `Status = 'Completed'` and prefixed with `[CANCELLED]` in their subject line.
* Cancellation notices are dispatched to the customer.

### 4. Integrity Protection: Delete Guard (`before delete`)
To prevent historical data loss, attempting to delete an appointment with `Status__c = 'Completed'` is immediately blocked:

```apex
private static void onBeforeDelete(Map<Id, Appointment__c> oldMap) {
    for (Appointment__c apt : oldMap.values()) {
        if (apt.Status__c == 'Completed') {
            apt.addError('Completed appointments cannot be deleted.');
        }
    }
}
```

---

## Unit Testing the Automation

To ensure production-grade reliability, we implemented [`AppointmentTriggerTest.cls`](force-app/main/default/classes/AppointmentTriggerTest.cls) utilizing our Step 3 test factories:

* **`testTaskCreatedOnAppointmentInsert`**: Verifies that inserting an appointment creates an associated `Task` with correct `WhatId`, `WhoId`, and `Not Started` status.
* **`testCancellationClosesOpenTask`**: Verifies that cancelling an appointment automatically closes pending tasks and updates subject lines.
* **`testDeleteCompletedAppointmentPrevented`**: Verifies that completed bookings cannot be deleted from the database.
* **`testDefaultStatusEnforced`**: Verifies that blank status fields automatically default to `'Scheduled'`.

---

## DX Verdict & Tool Feedback

### What Shined
1. **Separation of Concerns by Default**: `hob create trigger` prevents junior and senior developers alike from writing dirty triggers by providing the industry-standard pattern out of the box.
2. **Deterministic File Placement**: Triggers are routed to `force-app/main/default/triggers/` and handlers to `force-app/main/default/classes/` automatically.

### Opportunities for Hob's Backlog
1. **Companion Test Generation (`--with-test`) for Triggers**:
   - `hob create apex` supports `--with-test`. Bringing `--with-test` to `hob create trigger` (e.g. scaffolding `AppointmentTriggerTest.cls` with `@TestSetup` and DML insertion tests) would complete the TDD loop for triggers.

---

## What's Next in Part 6

With our data model, security permissions, test factories, core service engines, and server-side automation complete, we are ready to build the user experience!

In **Part 6**, we will explore:
* **"Building Modern Lightning UIs Fast: Scaffolded LWCs with Hob"**
* Using `hob create lwc <name>` to scaffold multi-step Lightning Web Components.
* Assembling the operator booking wizard (`appointmentWizard`) and embedding it into a dedicated Lightning App page.
