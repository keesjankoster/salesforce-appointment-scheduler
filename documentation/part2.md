# Part 2: Instant Least-Privilege Access — Generating Permission Sets with Hob

> *Building clean, deployment-ready permission sets from the terminal without profile bloat, browser lag, or manual XML surgery.*

---

## Introduction: The Death of Profiles & The Security Scaffolding Challenge

Salesforce has made its direction crystal clear: **Profiles are for baseline connectivity and login restrictions; Permission Sets and Permission Set Groups are for authorization.**

In a well-architected Salesforce DX project, we design for least-privilege access from Day 1. Every custom capability should ship with dedicated, granular permission sets rather than relying on bloated System Administrator profile overrides.

However, anyone who has built permission sets knows the pain:
1. **The Web UI Setup Crawl**: You navigate to Setup &rarr; Permission Sets &rarr; *Object Settings*. For 7 objects, you must click into each object page, click *Edit*, tick Read, Create, Edit, Delete, View All, scroll down through dozens of fields to check Read and Edit for each, click *Save*, wait for the redirect, and repeat 7 times.
2. **The "Everything or Nothing" Scratch Org Trap**: Developers often skip building permission sets until the end of a project because it is too tedious. Instead, they develop as System Administrator—only to discover during UAT or production deployment that users cannot see fields, buttons, or records due to missing Field-Level Security (FLS).
3. **Manual XML Merge Conflicts**: Crafting a `.permissionset-meta.xml` manually means writing repetitive `<objectPermissions>`, `<fieldPermissions>`, and `<recordTypeVisibilities>` blocks, where a single misspelled field or duplicate tag causes cryptic deployment errors.

In **Step 2** of building the **Salesforce Appointment Scheduler**, we address security immediately using **Hob: The Salesforce House-Elf** (`hob create permset`).

---

## The Persona: `Appointment_Scheduler_Operator`

Our application is operated by headquarters coordination staff who handle customer inquiries, match them with nearby branch locations, and book service appointments with qualified technicians.

To perform their role, an Operator requires:
* **Full CRUD & View All** on our four custom objects:
  * `Appointment__c`
  * `Service_Type__c`
  * `Staff_Service_Type__c`
  * `Staff_Working_Hours__c`
* **Read / Create / Edit / View All** on standard CRM entities:
  * `Account` (Branches)
  * `Contact` (Customers and Location Staff)
  * `Task` (Follow-up activities)
* **Field-Level Security (FLS)** on custom fields.
* **Record Type Visibility** for `Account.Location`, `Contact.Customer`, and `Contact.Location_Staff`.

---

## Scaffolding the Permission Set with Hob

Hob provides a dedicated command to scaffold permission sets with multi-object permissions pre-wired in seconds:

```bash
hob create permset Appointment_Scheduler_Operator \
  -l "Appointment Scheduler Operator" \
  -d "Grants access to Appointment Scheduler objects, fields, and operations" \
  --objects Appointment__c Service_Type__c Staff_Service_Type__c Staff_Working_Hours__c Account Contact Task
```

### The Terminal Output

```
  🧙 Hob — The Salesforce House-Elf 🧦
  "Loyal, quiet, and tireless assistance for your Salesforce Development."

✔ Created Permission Set 'Appointment_Scheduler_Operator'

🧦 Hob's wand granted the permission set boilerplate:

  Name:        Appointment_Scheduler_Operator
  Label:       Appointment Scheduler Operator
  Objects:     Appointment__c, Service_Type__c, Staff_Service_Type__c, Staff_Working_Hours__c, Account, Contact, Task
  File:        force-app/main/default/permissionsets/Appointment_Scheduler_Operator.permissionset-meta.xml

🧦 Assign to your active org with: sf org assign permset -n Appointment_Scheduler_Operator
```

With one command, Hob created `Appointment_Scheduler_Operator.permissionset-meta.xml` and pre-configured complete `<objectPermissions>` tags for all 7 objects:

```xml
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Appointment__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
```

---

## Deep Dive: The Critical Rules of Salesforce FLS & Required Fields

While object-level permissions provide the entry gate, non-admin users in Salesforce cannot read or write data without **Field-Level Security (FLS)** and **Record Type Visibilities**.

Here we encounter an important Salesforce metadata nuance that catches many developers off-guard:

### 1. The "Universally Required" Field Trap
In our Step 1 schema, fields like `Appointment__c.Customer__c`, `Appointment__c.Start_Time__c`, and `Service_Type__c.Duration_Minutes__c` were scaffolded with `<required>true</required>`.

In Salesforce:
> **Universally required fields cannot have `<fieldPermissions>` defined in a permission set.**

If you include a required field in a permission set's `<fieldPermissions>` block, the Metadata API deployment will immediately reject it:
```
Error: Cannot specify fieldPermissions for a required field
```
Because a required field is mandatory across the entire database, Salesforce automatically grants Read and Edit access to any user who has access to the parent object.

### 2. Granting FLS for Non-Required Fields
For optional and checkbox fields, explicit `<fieldPermissions>` are mandatory. We include permissions for all optional custom fields:
- `Account.Active__c`
- `Appointment__c.Notes__c`
- `Service_Type__c.Active__c`
- `Service_Type__c.Description__c`
- `Staff_Service_Type__c.Active__c`
- `Staff_Working_Hours__c.Active__c`

```xml
    <fieldPermissions>
        <editable>true</editable>
        <field>Appointment__c.Notes__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Account.Active__c</field>
        <readable>true</readable>
    </fieldPermissions>
```

### 3. Record Type Visibilities
To enable operators to create and view branch accounts and distinct customer vs. staff contacts, we expose our record types:

```xml
    <recordTypeVisibilities>
        <recordType>Account.Location</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <recordType>Contact.Customer</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <recordType>Contact.Location_Staff</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
```

---

## Developer Experience (DX) & Tool Feedback

### What Shined
1. **Multi-Object Syntax**: Passing multiple objects (`--objects Obj1 Obj2 Obj3`) in one pass saved creating and configuring 7 individual permission blocks.
2. **Clean, Minimal XML**: The generated file is deterministic, formatted with standard indentation, and free of extraneous profile junk.
3. **Instant CLI Feedback**: Hob reminded us immediately of the assignment command (`sf org assign permset -n Appointment_Scheduler_Operator`), shortening the cognitive loop between scaffolding and deployment.

### Opportunities for Hob Enhancement
1. **Automatic FLS Discovery (`--include-fields` or `--auto-fls`)**:
   - Hob could inspect the local `force-app` directory for the specified objects, detect all custom fields, automatically filter out universally required fields (`<required>true</required>`), and generate appropriate `<fieldPermissions>`.
2. **Record Type Visibility Flag (`--record-types`)**:
   - Allowing flags like `--record-types Account.Location Contact.Customer` to automatically add `<recordTypeVisibilities>`.

---

## Summary & What's Next in Part 3

In just two quick steps, we have:
1. **Part 1**: Scaffolding the complete data model (4 custom objects, 20+ fields, standard object extensions).
2. **Part 2**: Built a clean, least-privilege security layer (`Appointment_Scheduler_Operator`).

With our data and security foundations in place, we need robust test fixtures before writing domain logic. In **Part 3**, we will tackle:
* **"Standardizing Test Hygiene: In-Memory vs DML Factories with Hob"**
* Using `hob create factory` to scaffold high-performance Apex test data factories that support both fast in-memory mocking and persistent DML creation.
