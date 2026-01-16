// lib/core/constants/app_constants.dart
class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String propertiesCollection = 'properties';
  static const String favoritesCollection = 'favorites';
  
  // User Roles
  static const String roleTenant = 'tenant';
  static const String roleLandlord = 'landlord';
  static const String roleAdmin = 'admin';
  
  // Property Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  
  // Property Types
  static const List<String> propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'Studio',
    'Condominium',
    'Commercial',
    'Office',
    'Shop',
    'Land',
  ];

  // Locations in Addis Ababa
  static const List<String> locations = [
    'Bole',
    'Piassa',
    'Megenagna',
    'Saris',
    'Merkato',
    'Kazanchis',
    'Meskel Square',
    'Lideta',
    'Gofa',
    'Summit',
    'Gerji',
    'CMC',
    'Yeka',
    'Kolfe',
    'Nifas Silk',
    'Akaki',
  ];

  // Amenities
  static const List<String> amenities = [
    'Parking',
    'WiFi',
    'Furnished',
    'Balcony',
    'Garden',
    'Swimming Pool',
    'Gym',
    'Security',
    'Backup Generator',
    'Water 24/7',
    'Electricity 24/7',
    'Elevator',
    'Pet Friendly',
    'Laundry',
    'Air Conditioning',
  ];

  // Property Status List
  static const List<String> propertyStatusList = [
    statusPending,
    statusApproved,
    statusRejected,
  ];
}