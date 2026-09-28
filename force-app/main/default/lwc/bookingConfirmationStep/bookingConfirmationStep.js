import { LightningElement, api, track } from 'lwc';
import bookAppointment from '@salesforce/apex/AppointmentService.bookAppointment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BookingConfirmationStep extends LightningElement {
    @api customer;
    @api service;
    @api location;
    @api selectedSlot;
    @api notes;

    @track isBooking = false;
    @track bookedAppointment = null;

    get isReviewState() {
        return !this.bookedAppointment;
    }

    get isSuccessState() {
        return !!this.bookedAppointment;
    }

    get hasNotes() {
        return this.notes && this.notes.trim() !== '';
    }

    get formattedStartTime() {
        if (!this.selectedSlot?.startTime) return '';
        try {
            const dt = new Date(this.selectedSlot.startTime);
            return dt.toLocaleDateString('en-GB', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
        } catch {
            return this.selectedSlot.startTime;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back', { bubbles: true, composed: true }));
    }

    async handleConfirmBooking() {
        this.isBooking = true;
        try {
            const apt = await bookAppointment({
                customerId: this.customer.Id,
                locationId: this.location.locationId,
                staffId: this.selectedSlot.staffId,
                serviceTypeId: this.service.Id,
                startTime: this.selectedSlot.startTime,
                endTime: this.selectedSlot.endTime,
                notes: this.notes
            });

            this.bookedAppointment = apt;
            this.showToast('Appointment Booked!', `Appointment ${apt.Name} successfully scheduled.`, 'success');
        } catch (error) {
            this.showToast('Booking Error', error?.body?.message || error.message, 'error');
        } finally {
            this.isBooking = false;
        }
    }

    handleReset() {
        this.dispatchEvent(new CustomEvent('resetwizard', { bubbles: true, composed: true }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
