@IsTest
private class LocationServiceTest {

    @TestSetup
    static void setupTestData() {
        // 1. Create 2 branch locations: London and Birmingham
        Account londonBranch = AccountDataFactory.createAccount(new Map<String, Object>{
            'Name' => 'London Branch',
            'ShippingStreet' => '100 Cheapside',
            'ShippingCity' => 'London',
            'ShippingPostalCode' => 'EC2V 6DN',
            'ShippingLatitude' => 51.5142,
            'ShippingLongitude' => -0.0931
        });

        Account birminghamBranch = AccountDataFactory.createAccount(new Map<String, Object>{
            'Name' => 'Birmingham Branch',
            'ShippingStreet' => '1 Colmore Row',
            'ShippingCity' => 'Birmingham',
            'ShippingPostalCode' => 'B3 2QD',
            'ShippingLatitude' => 52.4831,
            'ShippingLongitude' => -1.8998
        });

        // 2. Create staff
        Contact londonStaff = ContactDataFactory.createStaffContact(londonBranch.Id, new Map<String, Object>{
            'FirstName' => 'Alice',
            'LastName' => 'Londoner'
        });

        Contact bhamStaff = ContactDataFactory.createStaffContact(birminghamBranch.Id, new Map<String, Object>{
            'FirstName' => 'Bob',
            'LastName' => 'Midlander'
        });

        // 3. Create service types
        Service_Type__c service1 = Service_TypeDataFactory.createService_Type(new Map<String, Object>{
            'Name' => 'General Consultation',
            'Duration_Minutes__c' => 30
        });

        Service_Type__c service2 = Service_TypeDataFactory.createService_Type(new Map<String, Object>{
            'Name' => 'Advanced Diagnostics',
            'Duration_Minutes__c' => 120
        });

        // 4. Qualify London staff for both, Birmingham staff only for service1
        Staff_Service_TypeDataFactory.createStaffServiceType(londonStaff.Id, service1.Id, null);
        Staff_Service_TypeDataFactory.createStaffServiceType(londonStaff.Id, service2.Id, null);
        Staff_Service_TypeDataFactory.createStaffServiceType(bhamStaff.Id, service1.Id, null);
    }

    @IsTest
    static void testGetNearestLocationsProximity() {
        Service_Type__c service = [SELECT Id FROM Service_Type__c WHERE Name = 'General Consultation' LIMIT 1];

        // Customer in London (SW1A 2AA: Lat 51.5034, Lon -0.1276)
        Decimal custLat = 51.5034;
        Decimal custLon = -0.1276;

        Test.startTest();
        List<LocationService.LocationSearchResult> results = LocationService.getNearestLocations(
            service.Id,
            custLat,
            custLon,
            5
        );
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Both branches provide General Consultation');
        // Closest should be London
        Assert.areEqual('London Branch', results[0].locationName, 'London branch should be first for a London customer');
        Assert.isTrue(results[0].distanceKm < results[1].distanceKm, 'First result should have shorter distance');
        Assert.areEqual(1, results[0].qualifiedStaff.size(), 'London should have 1 qualified staff');
    }

    @IsTest
    static void testGetNearestLocationsServiceFiltering() {
        Service_Type__c service2 = [SELECT Id FROM Service_Type__c WHERE Name = 'Advanced Diagnostics' LIMIT 1];

        Test.startTest();
        List<LocationService.LocationSearchResult> results = LocationService.getNearestLocations(
            service2.Id,
            51.5034,
            -0.1276,
            5
        );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Only London Branch has staff qualified for Advanced Diagnostics');
        Assert.areEqual('London Branch', results[0].locationName);
    }

    @IsTest
    static void testCalculateHaversineDistanceKm() {
        // Distance between London (51.5074, -0.1278) and Birmingham (52.4862, -1.8904) is ~163 km
        Double dist = LocationService.calculateHaversineDistanceKm(51.5074, -0.1278, 52.4862, -1.8904);
        Assert.isNotNull(dist);
        Assert.isTrue(dist > 150.0 && dist < 175.0, 'Distance should be approximately 163 km, actual: ' + dist);

        // Null coordinate check
        Assert.isNull(LocationService.calculateHaversineDistanceKm(null, 0.0, 1.0, 1.0));
    }

    @IsTest
    static void testNullServiceTypeThrowsException() {
        Boolean caught = false;
        try {
            LocationService.getNearestLocations(null, 51.5, -0.1, 5);
        } catch (LocationService.LocationServiceException ex) {
            caught = true;
        }
        Assert.isTrue(caught, 'Should throw LocationServiceException for null service type');
    }
}
