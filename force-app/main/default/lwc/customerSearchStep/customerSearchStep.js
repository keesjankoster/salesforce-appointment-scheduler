import { LightningElement, track } from 'lwc';
import searchCustomers from '@salesforce/apex/CustomerService.searchCustomers';
import createCustomer from '@salesforce/apex/CustomerService.createCustomer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomerSearchStep extends LightningElement {
    @track searchTerm = '';
    @track postalCode = '';
    @track searchResults = [];
    @track isLoading = false;
    @track searchPerformed = false;

    // New Customer form
    @track newFirstName = '';
    @track newLastName = '';
    @track newEmail = '';
    @track newPhone = '';
    @track newStreet = '';
    @track newCity = '';
    @track newPostalCode = '';

    get hasResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get noResultsFound() {
        return this.searchPerformed && (!this.searchResults || this.searchResults.length === 0) && !this.isLoading;
    }

    get isRegisterDisabled() {
        return !this.newLastName || this.newLastName.trim() === '';
    }

    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    handlePostalCodeChange(event) {
        this.postalCode = event.target.value;
    }

    handleNewFirstNameChange(event) {
        this.newFirstName = event.target.value;
    }

    handleNewLastNameChange(event) {
        this.newLastName = event.target.value;
    }

    handleNewEmailChange(event) {
        this.newEmail = event.target.value;
    }

    handleNewPhoneChange(event) {
        this.newPhone = event.target.value;
    }

    handleNewStreetChange(event) {
        this.newStreet = event.target.value;
    }

    handleNewCityChange(event) {
        this.newCity = event.target.value;
    }

    handleNewPostalCodeChange(event) {
        this.newPostalCode = event.target.value;
    }

    async handleSearch() {
        this.isLoading = true;
        this.searchPerformed = true;

        try {
            const results = await searchCustomers({
                searchTerm: this.searchTerm,
                postalCode: this.postalCode
            });
            this.searchResults = results;
        } catch (error) {
            this.showToast('Error searching customers', error?.body?.message || error.message, 'error');
            this.searchResults = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleSelectCustomer(event) {
        const customerId = event.target.dataset.id;
        const selected = this.searchResults.find((c) => c.Id === customerId);
        if (selected) {
            this.dispatchCustomerSelected(selected);
        }
    }

    async handleCreateCustomer() {
        if (!this.newLastName || this.newLastName.trim() === '') {
            this.showToast('Validation Error', 'Last Name is required.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            const created = await createCustomer({
                firstName: this.newFirstName,
                lastName: this.newLastName,
                email: this.newEmail,
                phone: this.newPhone,
                street: this.newStreet,
                city: this.newCity,
                postalCode: this.newPostalCode,
                country: 'United Kingdom',
                latitude: null,
                longitude: null
            });

            this.showToast('Success', 'Customer registered successfully', 'success');
            this.dispatchCustomerSelected(created);
        } catch (error) {
            this.showToast('Error creating customer', error?.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    dispatchCustomerSelected(customer) {
        this.dispatchEvent(
            new CustomEvent('customerselected', {
                detail: customer,
                bubbles: true,
                composed: true
            })
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
