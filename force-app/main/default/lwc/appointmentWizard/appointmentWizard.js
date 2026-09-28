import { LightningElement, track } from 'lwc';

export default class AppointmentWizard extends LightningElement {
    @track currentStep = '1';

    @track selectedCustomer = null;
    @track selectedService = null;
    @track selectedLocation = null;
    @track selectedSlot = null;
    @track bookingNotes = '';

    get isStep1() {
        return this.currentStep === '1';
    }

    get isStep2() {
        return this.currentStep === '2';
    }

    get isStep3() {
        return this.currentStep === '3';
    }

    get isStep4() {
        return this.currentStep === '4';
    }

    get hasContext() {
        return !!this.selectedCustomer || !!this.selectedService;
    }

    get canReset() {
        return this.currentStep !== '1';
    }

    handleCustomerSelected(event) {
        this.selectedCustomer = event.detail;
        this.currentStep = '2';
    }

    handleServiceSelected(event) {
        this.selectedService = event.detail;
        this.currentStep = '3';
    }

    handleSlotSelected(event) {
        this.selectedLocation = event.detail.location;
        this.selectedSlot = event.detail.slot;
        this.bookingNotes = event.detail.notes || '';
        this.currentStep = '4';
    }

    handleBackToStep3() {
        this.currentStep = '3';
    }

    handleResetWizard() {
        this.selectedCustomer = null;
        this.selectedService = null;
        this.selectedLocation = null;
        this.selectedSlot = null;
        this.bookingNotes = '';
        this.currentStep = '1';
    }
}
