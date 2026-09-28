import { LightningElement, wire, track } from 'lwc';
import getActiveServiceTypes from '@salesforce/apex/AvailabilityService.getActiveServiceTypes';

export default class ServiceSelectionStep extends LightningElement {
    @track services = [];
    @track isLoading = true;

    @wire(getActiveServiceTypes)
    wiredServices({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.services = data;
        } else if (error) {
            this.services = [];
            // eslint-disable-next-line no-console
            console.error('Error fetching service types:', error);
        }
    }

    get hasServices() {
        return this.services && this.services.length > 0;
    }

    get noServices() {
        return !this.isLoading && (!this.services || this.services.length === 0);
    }

    handleSelectService(event) {
        const serviceId = event.target.dataset.id;
        const selected = this.services.find((s) => s.Id === serviceId);
        if (selected) {
            this.dispatchEvent(
                new CustomEvent('serviceselected', {
                    detail: selected,
                    bubbles: true,
                    composed: true
                })
            );
        }
    }
}
