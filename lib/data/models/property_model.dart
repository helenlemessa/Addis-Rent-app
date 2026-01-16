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
    };
  }

  String get formattedPrice {
    return 'ETB ${price.toStringAsFixed(0)}/month';
  }
}

// Add this extension
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
    );
  }
}