public with sharing class CustomerService {

    public class CustomerServiceException extends Exception {}

    private static Id customerRecordTypeId {
        get {
            if (customerRecordTypeId == null) {
                customerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                    .get('Customer')
                    ?.getRecordTypeId();
            }
            return customerRecordTypeId;
        }
        set;
    }

    /**
     * Searches for existing Customer contacts by name, email, phone, or postal code.
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchCustomers(String searchTerm, String postalCode) {
        String query = 'SELECT Id, FirstName, LastName, Name, Email, Phone, MobilePhone, ' +
            'MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, ' +
            'MailingLatitude, MailingLongitude ' +
            'FROM Contact WHERE RecordTypeId = :customerRecordTypeId ';

        List<String> conditions = new List<String>();

        if (String.isNotBlank(searchTerm)) {
            String sanitizedTerm = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
            conditions.add('(FirstName LIKE :sanitizedTerm OR LastName LIKE :sanitizedTerm OR Email LIKE :sanitizedTerm OR Phone LIKE :sanitizedTerm)');
        }

        if (String.isNotBlank(postalCode)) {
            String sanitizedPostal = '%' + String.escapeSingleQuotes(postalCode.trim()) + '%';
            conditions.add('(MailingPostalCode LIKE :sanitizedPostal)');
        }

        if (!conditions.isEmpty()) {
            query += 'AND ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY LastName ASC, FirstName ASC LIMIT 25';

        return Database.query(query);
    }

    /**
     * Retrieves a single customer contact by Id.
     */
    @AuraEnabled(cacheable=true)
    public static Contact getCustomerById(Id customerId) {
        if (customerId == null) {
            throw new CustomerServiceException('Customer ID must not be null.');
        }

        List<Contact> customers = [
            SELECT Id, FirstName, LastName, Name, Email, Phone, MobilePhone,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                   MailingLatitude, MailingLongitude
            FROM Contact
            WHERE Id = :customerId
            LIMIT 1
        ];

        if (customers.isEmpty()) {
            throw new CustomerServiceException('Customer not found with ID: ' + customerId);
        }

        return customers[0];
    }

    /**
     * Creates and registers a new Customer contact.
     */
    @AuraEnabled
    public static Contact createCustomer(
        String firstName,
        String lastName,
        String email,
        String phone,
        String street,
        String city,
        String postalCode,
        String country,
        Decimal latitude,
        Decimal longitude
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
}
