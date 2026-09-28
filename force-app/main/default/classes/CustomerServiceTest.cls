@IsTest
private class CustomerServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create 2 test customers using ContactDataFactory
        ContactDataFactory.createContact(new Map<String, Object>{
            'FirstName' => 'Arthur',
            'LastName' => 'Dent',
            'Email' => 'arthur.dent@example.com',
            'Phone' => '02079460001',
            'MailingPostalCode' => 'EC1A 1BB'
        });

        ContactDataFactory.createContact(new Map<String, Object>{
            'FirstName' => 'Ford',
            'LastName' => 'Prefect',
            'Email' => 'ford.prefect@example.com',
            'Phone' => '02079460002',
            'MailingPostalCode' => 'M1 1AA'
        });
    }

    @IsTest
    static void testSearchCustomersByTerm() {
        Test.startTest();
        List<Contact> results = CustomerService.searchCustomers('Dent', null);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should find one customer matching Dent');
        Assert.areEqual('Arthur', results[0].FirstName);
    }

    @IsTest
    static void testSearchCustomersByPostalCode() {
        Test.startTest();
        List<Contact> results = CustomerService.searchCustomers(null, 'M1 1AA');
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should find one customer matching postal code M1 1AA');
        Assert.areEqual('Ford', results[0].FirstName);
    }

    @IsTest
    static void testCreateCustomerSuccess() {
        Test.startTest();
        Contact created = CustomerService.createCustomer(
            'Trillian',
            'Astra',
            'trillian@example.com',
            '07700900999',
            '42 Galaxy Way',
            'London',
            'SW1A 1AA',
            'United Kingdom',
            51.5014,
            -0.1419
        );
        Test.stopTest();

        Assert.isNotNull(created.Id, 'Customer should be inserted with an ID');
        Assert.areEqual('Trillian', created.FirstName);
        Assert.areEqual('Astra', created.LastName);
        Assert.areEqual('SW1A 1AA', created.MailingPostalCode);
    }

    @IsTest
    static void testCreateCustomerMissingLastName() {
        Boolean exceptionCaught = false;

        Test.startTest();
        try {
            CustomerService.createCustomer(
                'Zaphod',
                '',
                'zaphod@example.com',
                null,
                null,
                null,
                null,
                null,
                null,
                null
            );
        } catch (CustomerService.CustomerServiceException ex) {
            exceptionCaught = true;
            Assert.isTrue(ex.getMessage().contains('Last name is required'), 'Expected validation error');
        }
        Test.stopTest();

        Assert.isTrue(exceptionCaught, 'Expected CustomerServiceException to be thrown');
    }

    @IsTest
    static void testGetCustomerById() {
        Contact existing = [SELECT Id FROM Contact WHERE LastName = 'Dent' LIMIT 1];

        Test.startTest();
        Contact retrieved = CustomerService.getCustomerById(existing.Id);
        Test.stopTest();

        Assert.areEqual('Arthur', retrieved.FirstName);
        Assert.areEqual('Dent', retrieved.LastName);
    }
}
