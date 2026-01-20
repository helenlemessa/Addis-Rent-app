// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // Helper function to safely parse dates
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
    } catch (e) {
      print('⚠️ Error parsing date: $dateValue - $e');
    }
    return null;
  }

  // Get or create createdAt - REQUIRED field
  DateTime createdAt;
  try {
    final createdAtValue = map['createdAt'];
    if (createdAtValue == null) {
      print('⚠️ User $id missing createdAt, using current date');
      createdAt = DateTime.now();
    } else {
      createdAt = _parseDate(createdAtValue) ?? DateTime.now();
    }
  } catch (e) {
    print('⚠️ Error with createdAt for user $id: $e');
    createdAt = DateTime.now();
  }

  return UserModel(
    id: id,
    fullName: map['fullName']?.toString().trim() ?? 'Unknown User',
    email: (map['email'] ?? '').toString().toLowerCase().trim(),
    phone: map['phone']?.toString().trim() ?? '',
    role: map['role']?.toString().toLowerCase() ?? 'tenant',
    profileImage: map['profileImage']?.toString(),
    isVerified: map['isVerified'] == true,
    isSuspended: map['isSuspended'] == true,
    suspensionReason: map['suspensionReason']?.toString(),
    suspendedAt: _parseDate(map['suspendedAt']),
    verifiedAt: _parseDate(map['verifiedAt']),
    createdAt: createdAt,
    updatedAt: _parseDate(map['updatedAt']),
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