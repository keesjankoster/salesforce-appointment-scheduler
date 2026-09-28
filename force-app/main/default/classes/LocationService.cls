public with sharing class LocationService {

    public class LocationServiceException extends Exception {}

    public class StaffMember {
        @AuraEnabled public Id staffId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }

        public StaffMember(Contact c) {
            this.staffId = c.Id;
            this.name = c.Name;
            this.title = c.Title;
            this.email = c.Email;
            this.phone = c.Phone;
        }
    }

    public class LocationSearchResult implements Comparable {
        @AuraEnabled public Id locationId { get; set; }
        @AuraEnabled public String locationName { get; set; }
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String postalCode { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public Double distanceKm { get; set; }
        @AuraEnabled public List<StaffMember> qualifiedStaff { get; set; }

        public LocationSearchResult() {
            this.qualifiedStaff = new List<StaffMember>();
        }

        public Integer compareTo(Object compareTo) {
            LocationSearchResult other = (LocationSearchResult) compareTo;
            if (this.distanceKm == null && other.distanceKm == null) return 0;
            if (this.distanceKm == null) return 1;
            if (other.distanceKm == null) return -1;
            if (this.distanceKm < other.distanceKm) return -1;
            if (this.distanceKm > other.distanceKm) return 1;
            return 0;
        }
    }

    /**
     * Finds the closest branch locations providing the requested Service Type,
     * ranked by proximity to the customer coordinates.
     */
    @AuraEnabled(cacheable=true)
    public static List<LocationSearchResult> getNearestLocations(
        Id serviceTypeId,
        Decimal customerLat,
        Decimal customerLon,
        Integer maxResults
    ) {
        if (serviceTypeId == null) {
            throw new LocationServiceException('Service Type ID must not be null.');
        }

        Integer limitCount = (maxResults != null && maxResults > 0) ? maxResults : 5;

        // 1. Find all qualified active staff members for this service type
        List<Staff_Service_Type__c> qualifications = [
            SELECT Id, Staff__c, Staff__r.Name, Staff__r.Title, Staff__r.Email, Staff__r.Phone,
                   Staff__r.AccountId, Staff__r.Account.Name
            FROM Staff_Service_Type__c
            WHERE Service_Type__c = :serviceTypeId
              AND Active__c = true
              AND Staff__r.AccountId != null
        ];

        if (qualifications.isEmpty()) {
            return new List<LocationSearchResult>();
        }

        // Map branch Account Id -> List of qualified staff
        Map<Id, List<StaffMember>> branchStaffMap = new Map<Id, List<StaffMember>>();
        for (Staff_Service_Type__c q : qualifications) {
            Id branchId = q.Staff__r.AccountId;
            if (!branchStaffMap.containsKey(branchId)) {
                branchStaffMap.put(branchId, new List<StaffMember>());
            }
            branchStaffMap.get(branchId).add(new StaffMember(q.Staff__r));
        }

        Set<Id> qualifiedBranchIds = branchStaffMap.keySet();

        // 2. Query branch Accounts
        List<Account> branches = [
            SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState,
                   ShippingPostalCode, ShippingCountry, ShippingLatitude, ShippingLongitude
            FROM Account
            WHERE Id IN :qualifiedBranchIds
              AND Active__c = true
        ];

        // 3. Construct results and compute distances
        List<LocationSearchResult> results = new List<LocationSearchResult>();

        for (Account branch : branches) {
            LocationSearchResult res = new LocationSearchResult();
            res.locationId = branch.Id;
            res.locationName = branch.Name;
            res.street = branch.ShippingStreet;
            res.city = branch.ShippingCity;
            res.postalCode = branch.ShippingPostalCode;
            res.latitude = branch.ShippingLatitude;
            res.longitude = branch.ShippingLongitude;
            res.qualifiedStaff = branchStaffMap.get(branch.Id);

            if (customerLat != null && customerLon != null && branch.ShippingLatitude != null && branch.ShippingLongitude != null) {
                res.distanceKm = calculateHaversineDistanceKm(
                    customerLat,
                    customerLon,
                    branch.ShippingLatitude,
                    branch.ShippingLongitude
                );
            }

            results.add(res);
        }

        // Sort by distance ascending
        results.sort();

        // Limit results
        if (results.size() > limitCount) {
            List<LocationSearchResult> limited = new List<LocationSearchResult>();
            for (Integer i = 0; i < limitCount; i++) {
                limited.add(results[i]);
            }
            return limited;
        }

        return results;
    }

    /**
     * Calculates the great-circle distance between two coordinates in kilometers using Haversine formula.
     */
    public static Double calculateHaversineDistanceKm(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2) {
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
            return null;
        }

        Double earthRadiusKm = 6371.0;
        Double dLat = toRadians(Double.valueOf(lat2 - lat1));
        Double dLon = toRadians(Double.valueOf(lon2 - lon1));
        Double rLat1 = toRadians(Double.valueOf(lat1));
        Double rLat2 = toRadians(Double.valueOf(lat2));

        Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(rLat1) * Math.cos(rLat2) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        Double distance = earthRadiusKm * c;
        // Round to 1 decimal place
        return Math.round(distance * 10.0) / 10.0;
    }

    private static Double toRadians(Double degrees) {
        return degrees * (Math.PI / 180.0);
    }
}
