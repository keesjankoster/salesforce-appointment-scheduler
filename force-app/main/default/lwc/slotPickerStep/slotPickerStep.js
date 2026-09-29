import { LightningElement, api, track } from 'lwc';
import getNearestLocations from '@salesforce/apex/LocationService.getNearestLocations';
import getAvailableSlots from '@salesforce/apex/AvailabilityService.getAvailableSlots';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SlotPickerStep extends LightningElement {
    @api customer;
    @api service;

    @track locations = [];
    @track selectedLocation = null;
    @track selectedDate = '';
    @track minDate = '';
    @track slots = [];
    @track selectedSlot = null;
    @track notes = '';

    @track isLoadingLocations = true;
    @track isLoadingSlots = false;

    connectedCallback() {
        // Set min date to tomorrow
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        this.selectedDate = tomorrow.toISOString().split('T')[0];
        this.minDate = this.selectedDate;

        this.loadLocations();
    }

    get hasLocations() {
        return this.locations && this.locations.length > 0;
    }

    get noLocationsFound() {
        return !this.isLoadingLocations && (!this.locations || this.locations.length === 0);
    }

    get hasSlots() {
        return this.slots && this.slots.length > 0;
    }

    get noSlotsAvailable() {
        return !this.isLoadingSlots && (!this.slots || this.slots.length === 0);
    }

    get isProceedDisabled() {
        return !this.selectedLocation || !this.selectedSlot;
    }

    async loadLocations() {
        this.isLoadingLocations = true;
        try {
            const results = await getNearestLocations({
                serviceTypeId: this.service.Id,
                customerLat: this.customer?.MailingLatitude || null,
                customerLon: this.customer?.MailingLongitude || null,
                maxResults: 6
            });

            this.locations = results.map((loc) => {
                const staffNames = loc.qualifiedStaff ? loc.qualifiedStaff.map((s) => s.name).join(', ') : 'None';
                return {
                    ...loc,
                    staffSummary: staffNames,
                    cardClass: 'location-card slds-box slds-var-m-bottom_small'
                };
            });

            // Auto-select first (closest) location
            if (this.locations.length > 0) {
                this.selectLocation(this.locations[0]);
            }
        } catch (error) {
            this.showToast('Error finding branch locations', error?.body?.message || error.message, 'error');
            this.locations = [];
        } finally {
            this.isLoadingLocations = false;
        }
    }

    handleSelectLocation(event) {
        const locId = event.currentTarget.dataset.id;
        const target = this.locations.find((l) => l.locationId === locId);
        if (target) {
            this.selectLocation(target);
        }
    }

    selectLocation(location) {
        this.selectedLocation = location;
        this.selectedSlot = null;

        // Update card classes
        this.locations = this.locations.map((l) => ({
            ...l,
            cardClass:
                l.locationId === location.locationId
                    ? 'location-card slds-box slds-var-m-bottom_small selected-location'
                    : 'location-card slds-box slds-var-m-bottom_small'
        }));

        this.loadSlots();
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.selectedSlot = null;
        this.loadSlots();
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
    }

    async loadSlots() {
        if (!this.selectedLocation || !this.selectedDate) return;

        this.isLoadingSlots = true;
        try {
            const rawSlots = await getAvailableSlots({
                locationId: this.selectedLocation.locationId,
                serviceTypeId: this.service.Id,
                targetDate: this.selectedDate
            });

            this.slots = rawSlots.map((slot) => ({
                ...slot,
                btnClass: 'slot-button slds-var-m-around_xx-small'
            }));
        } catch (error) {
            this.showToast('Error loading slots', error?.body?.message || error.message, 'error');
            this.slots = [];
        } finally {
            this.isLoadingSlots = false;
        }
    }

    handleSelectSlot(event) {
        const slotKey = event.currentTarget.dataset.key;
        const targetSlot = this.slots.find((s) => s.slotKey === slotKey);
        if (targetSlot) {
            this.selectedSlot = targetSlot;
            this.slots = this.slots.map((s) => ({
                ...s,
                btnClass:
                    s.slotKey === slotKey
                        ? 'slot-button slds-var-m-around_xx-small selected-slot'
                        : 'slot-button slds-var-m-around_xx-small'
            }));
        }
    }

    handleProceed() {
        if (!this.selectedLocation || !this.selectedSlot) return;

        this.dispatchEvent(
            new CustomEvent('slotselected', {
                detail: {
                    location: this.selectedLocation,
                    slot: this.selectedSlot,
                    notes: this.notes
                },
                bubbles: true,
                composed: true
            })
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
