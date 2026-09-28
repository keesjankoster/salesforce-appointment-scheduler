public with sharing class AppointmentTriggerHandler {

    public static void handleTrigger(
        System.TriggerOperation operationType,
        List<Appointment__c> newList,
        Map<Id, Appointment__c> oldMap
    ) {
        switch on operationType {
            when BEFORE_INSERT {
                onBeforeInsert(newList);
            }
            when AFTER_INSERT {
                onAfterInsert(newList);
            }
            when BEFORE_UPDATE {
                onBeforeUpdate(newList, oldMap);
            }
            when AFTER_UPDATE {
                onAfterUpdate(newList, oldMap);
            }
            when BEFORE_DELETE {
                onBeforeDelete(oldMap);
            }
            when AFTER_DELETE {
                onAfterDelete(oldMap);
            }
            when AFTER_UNDELETE {
                onAfterUndelete(newList);
            }
        }
    }

    private static void onBeforeInsert(List<Appointment__c> newList) {
        // Enforce default status if missing
        for (Appointment__c apt : newList) {
            if (String.isBlank(apt.Status__c)) {
                apt.Status__c = 'Scheduled';
            }
        }
    }

    private static void onAfterInsert(List<Appointment__c> newList) {
        Set<Id> scheduledIds = new Set<Id>();
        for (Appointment__c apt : newList) {
            if (apt.Status__c == 'Scheduled') {
                scheduledIds.add(apt.Id);
            }
        }

        if (!scheduledIds.isEmpty()) {
            processNewAppointments(scheduledIds);
        }
    }

    private static void onBeforeUpdate(List<Appointment__c> newList, Map<Id, Appointment__c> oldMap) {
        // Validation or field transformations before update
    }

    private static void onAfterUpdate(List<Appointment__c> newList, Map<Id, Appointment__c> oldMap) {
        Set<Id> cancelledIds = new Set<Id>();
        for (Appointment__c apt : newList) {
            Appointment__c oldApt = oldMap.get(apt.Id);
            if (apt.Status__c == 'Cancelled' && oldApt.Status__c != 'Cancelled') {
                cancelledIds.add(apt.Id);
            }
        }

        if (!cancelledIds.isEmpty()) {
            processCancelledAppointments(cancelledIds);
        }
    }

    private static void onBeforeDelete(Map<Id, Appointment__c> oldMap) {
        // Guard against deleting completed appointments
        for (Appointment__c apt : oldMap.values()) {
            if (apt.Status__c == 'Completed') {
                apt.addError('Completed appointments cannot be deleted.');
            }
        }
    }

    private static void onAfterDelete(Map<Id, Appointment__c> oldMap) {
        // Cleanup or audit logging
    }

    private static void onAfterUndelete(List<Appointment__c> newList) {
        // Logic after records are restored
    }

    // =========================================================================
    // Automation Logic (Separation of Concerns)
    // =========================================================================

    /**
     * Creates standard Task records for staff and dispatches confirmation emails.
     */
    private static void processNewAppointments(Set<Id> appointmentIds) {
        List<Appointment__c> appointments = [
            SELECT Id, Name, Customer__c, Customer__r.Name, Customer__r.Email,
                   Location__c, Location__r.Name, Staff__c, Staff__r.Name, Staff__r.Email,
                   Service_Type__c, Service_Type__r.Name, Start_Time__c, End_Time__c, Notes__c
            FROM Appointment__c
            WHERE Id IN :appointmentIds
        ];

        List<Task> tasksToInsert = new List<Task>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Appointment__c apt : appointments) {
            String serviceName = apt.Service_Type__r != null ? apt.Service_Type__r.Name : 'Service Appointment';
            String customerName = apt.Customer__r != null ? apt.Customer__r.Name : 'Customer';
            String locationName = apt.Location__r != null ? apt.Location__r.Name : 'Branch';
            Date appointmentDate = apt.Start_Time__c != null ? apt.Start_Time__c.date() : Date.today();

            // 1. Create standard follow-up Task for location staff
            Task staffTask = new Task(
                WhatId = apt.Id,
                WhoId = apt.Staff__c,
                Subject = 'Service Appointment: ' + serviceName,
                ActivityDate = appointmentDate,
                Status = 'Not Started',
                Priority = 'Normal',
                Description = 'Upcoming appointment with ' + customerName + ' at ' + locationName + '.\n' +
                    'Start: ' + (apt.Start_Time__c != null ? apt.Start_Time__c.format('yyyy-MM-dd HH:mm') : 'N/A') + '\n' +
                    'Notes: ' + (String.isNotBlank(apt.Notes__c) ? apt.Notes__c : 'None')
            );
            tasksToInsert.add(staffTask);

            // 2. Prepare confirmation emails
            String formattedTime = apt.Start_Time__c != null ? apt.Start_Time__c.format('EEEE, d MMMM yyyy at HH:mm') : 'Scheduled Time';

            // Customer confirmation email
            if (apt.Customer__r != null && String.isNotBlank(apt.Customer__r.Email)) {
                Messaging.SingleEmailMessage custEmail = new Messaging.SingleEmailMessage();
                custEmail.setToAddresses(new List<String>{ apt.Customer__r.Email });
                custEmail.setSubject('Appointment Confirmed: ' + serviceName + ' with ' + locationName);
                custEmail.setPlainTextBody(
                    'Dear ' + customerName + ',\n\n' +
                    'Your appointment for ' + serviceName + ' has been confirmed!\n\n' +
                    'Details:\n' +
                    '• Date & Time: ' + formattedTime + '\n' +
                    '• Location: ' + locationName + '\n' +
                    '• Staff Specialist: ' + (apt.Staff__r != null ? apt.Staff__r.Name : 'Assigned Staff') + '\n\n' +
                    'If you need to reschedule or have questions, please contact your local branch.\n\n' +
                    'Best regards,\n' +
                    'The Appointment Scheduling Team'
                );
                emailsToSend.add(custEmail);
            }

            // Staff notification email
            if (apt.Staff__r != null && String.isNotBlank(apt.Staff__r.Email)) {
                Messaging.SingleEmailMessage staffEmail = new Messaging.SingleEmailMessage();
                staffEmail.setToAddresses(new List<String>{ apt.Staff__r.Email });
                staffEmail.setSubject('New Appointment Booked: ' + serviceName + ' - ' + customerName);
                staffEmail.setPlainTextBody(
                    'Hello ' + (apt.Staff__r != null ? apt.Staff__r.Name : 'Team') + ',\n\n' +
                    'A new service appointment has been scheduled with you.\n\n' +
                    'Details:\n' +
                    '• Customer: ' + customerName + '\n' +
                    '• Service: ' + serviceName + '\n' +
                    '• Date & Time: ' + formattedTime + '\n' +
                    '• Notes: ' + (String.isNotBlank(apt.Notes__c) ? apt.Notes__c : 'None') + '\n\n' +
                    'A follow-up task has been added to your activity queue.'
                );
                emailsToSend.add(staffEmail);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }

        if (!emailsToSend.isEmpty() && Limits.getEmailInvocations() < Limits.getLimitEmailInvocations()) {
            try {
                Messaging.sendEmail(emailsToSend, false);
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'Unable to send appointment confirmation emails: ' + ex.getMessage());
            }
        }
    }

    /**
     * Handles cancellation side-effects: closes pending tasks and notifies participants.
     */
    private static void processCancelledAppointments(Set<Id> cancelledIds) {
        // 1. Close open follow-up tasks
        List<Task> openTasks = [
            SELECT Id, Status, Subject
            FROM Task
            WHERE WhatId IN :cancelledIds
              AND Status != 'Completed'
        ];

        for (Task t : openTasks) {
            t.Status = 'Completed';
            t.Subject = '[CANCELLED] ' + t.Subject;
        }

        if (!openTasks.isEmpty()) {
            update openTasks;
        }

        // 2. Dispatch cancellation notices
        List<Appointment__c> cancelledApts = [
            SELECT Id, Name, Customer__r.Name, Customer__r.Email, Staff__r.Name, Staff__r.Email,
                   Service_Type__r.Name, Start_Time__c, Location__r.Name, Notes__c
            FROM Appointment__c
            WHERE Id IN :cancelledIds
        ];

        List<Messaging.SingleEmailMessage> cancellationEmails = new List<Messaging.SingleEmailMessage>();

        for (Appointment__c apt : cancelledApts) {
            String serviceName = apt.Service_Type__r != null ? apt.Service_Type__r.Name : 'Appointment';
            String formattedTime = apt.Start_Time__c != null ? apt.Start_Time__c.format('yyyy-MM-dd HH:mm') : 'Scheduled Time';

            if (apt.Customer__r != null && String.isNotBlank(apt.Customer__r.Email)) {
                Messaging.SingleEmailMessage custEmail = new Messaging.SingleEmailMessage();
                custEmail.setToAddresses(new List<String>{ apt.Customer__r.Email });
                custEmail.setSubject('Appointment Cancelled: ' + serviceName);
                custEmail.setPlainTextBody(
                    'Dear ' + apt.Customer__r.Name + ',\n\n' +
                    'Your appointment for ' + serviceName + ' on ' + formattedTime + ' has been cancelled.\n\n' +
                    'Please contact us if you wish to re-book.\n\nBest regards,\nScheduling Team'
                );
                cancellationEmails.add(custEmail);
            }
        }

        if (!cancellationEmails.isEmpty() && Limits.getEmailInvocations() < Limits.getLimitEmailInvocations()) {
            try {
                Messaging.sendEmail(cancellationEmails, false);
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'Unable to send cancellation emails: ' + ex.getMessage());
            }
        }
    }
}
