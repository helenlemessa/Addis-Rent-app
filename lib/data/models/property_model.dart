class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String propertyType;
  final double price;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final List<String> images;
  final String landlordId;
  final String landlordName;
  final String landlordPhone;
  final String landlordEmail;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;
  
  // NEW FIELDS for archival system
  final bool isArchived; // For soft delete
  final String? archiveReason; // 'landlord_deleted', 'admin_cleaned', 'rented'
  final DateTime? rentedAt; // When property was marked as rented
  final DateTime? archivedAt; // When property was archived
  final String? archivedBy; // Who archived it (landlordId or adminId)
  final bool isDeleted; // Hard delete flag (admin only)
   
  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.price,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.amenities,
    required this.images,
    required this.landlordId,
    required this.landlordName,
    required this.landlordPhone,
    required this.landlordEmail,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    
    // NEW: Default values for archival fields
    this.isArchived = false,
    this.archiveReason,
    this.rentedAt,
    this.archivedAt,
   
    this.archivedBy,
    this.isDeleted = false,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      propertyType: map['propertyType'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      amenities: List<String>.from(map['amenities'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      landlordId: map['landlordId'] ?? '',
      landlordName: map['landlordName'] ?? '',
      landlordPhone: map['landlordPhone'] ?? '',
      landlordEmail: map['landlordEmail'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      
      // NEW: Parse archival fields
      isArchived: map['isArchived'] ?? false,
      archiveReason: map['archiveReason'],
      rentedAt: map['rentedAt'] != null ? DateTime.parse(map['rentedAt']) : null,
      archivedAt: map['archivedAt'] != null ? DateTime.parse(map['archivedAt']) : null,
      archivedBy: map['archivedBy'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'propertyType': propertyType,
      'price': price,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'images': images,
      'landlordId': landlordId,
      'landlordName': landlordName,
      'landlordPhone': landlordPhone,
      'landlordEmail': landlordEmail,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      
      // NEW: Include archival fields
      'isArchived': isArchived,
      'archiveReason': archiveReason,
      'rentedAt': rentedAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'archivedBy': archivedBy,
      'isDeleted': isDeleted,
    };
  }

  String get formattedPrice {
    return 'ETB ${price.toStringAsFixed(0)}/month';
  }

  // Helper method to check if property is old (> 3 months)
  bool get isOldProperty {
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    return createdAt.isBefore(threeMonthsAgo);
  }

  // Check if property is rented/taken
  bool get isRented => rentedAt != null;

  // Check if property is active (not archived and approved)
  bool get isActive => !isArchived && status == 'approved';
}

// Keep your existing copyWith extension
extension PropertyModelCopyWith on PropertyModel {
  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? propertyType,
    double? price,
    String? location,
    int? bedrooms,
    int? bathrooms,
    List<String>? amenities,
    List<String>? images,
    String? landlordId,
    String? landlordName,
    String? landlordPhone,
    String? landlordEmail,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    
    // NEW: Archival fields
    bool? isArchived,
    String? archiveReason,
    DateTime? rentedAt,
    DateTime? archivedAt,
    String? archivedBy,
    bool? isDeleted,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyType: propertyType ?? this.propertyType,
      price: price ?? this.price,
      location: location ?? this.location,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      landlordId: landlordId ?? this.landlordId,
      landlordName: landlordName ?? this.landlordName,
      landlordPhone: landlordPhone ?? this.landlordPhone,
      landlordEmail: landlordEmail ?? this.landlordEmail,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      
      // NEW: Archival fields
      isArchived: isArchived ?? this.isArchived,
      archiveReason: archiveReason ?? this.archiveReason,
      rentedAt: rentedAt ?? this.rentedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}