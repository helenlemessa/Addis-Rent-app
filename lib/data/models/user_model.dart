// lib/data/models/user_model.dart
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role; // tenant, landlord, admin
  final String? profileImage;
  final bool isVerified;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.isVerified = false,
    this.isSuspended = false,
    this.suspensionReason,
    this.suspendedAt,
    this.verifiedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'tenant',
      profileImage: map['profileImage'],
      isVerified: map['isVerified'] ?? false,
      isSuspended: map['isSuspended'] ?? false,
      suspensionReason: map['suspensionReason'],
      suspendedAt: map['suspendedAt'] != null
          ? DateTime.parse(map['suspendedAt'])
          : null,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'suspendedAt': suspendedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? profileImage,
    bool? isVerified,
    bool? isSuspended,
    String? suspensionReason,
    DateTime? suspendedAt,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}