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
