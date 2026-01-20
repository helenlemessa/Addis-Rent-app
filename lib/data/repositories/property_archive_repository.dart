// Create new file: lib/data/repositories/property_archive_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class PropertyArchiveRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Landlord marks property as rented (archive)
  Future<void> markAsRented({
    required String propertyId,
    required String landlordId,
    String reason = 'Property rented',
  }) async {
    try {
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(propertyId)
          .update({
            'isArchived': true,
            'archiveReason': reason,
            'rentedAt': DateTime.now().toIso8601String(),
            'archivedAt': DateTime.now().toIso8601String(),
            'archivedBy': landlordId,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Landlord soft deletes property
  Future<void> softDeleteProperty({
    required String propertyId,
    required String landlordId,
    String reason = 'Landlord deleted',
  }) async {
    try {
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(propertyId)
          .update({
            'isArchived': true,
            'archiveReason': reason,
            'archivedAt': DateTime.now().toIso8601String(),
            'archivedBy': landlordId,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Admin hard deletes old properties
  Future<void> adminDeleteOldProperty({
    required String propertyId,
    required String adminId,
    String reason = 'Admin cleanup - Property older than 3 months',
  }) async {
    try {
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(propertyId)
          .update({
            'isArchived': true,
            'isDeleted': true,
            'archiveReason': reason,
            'archivedAt': DateTime.now().toIso8601String(),
            'archivedBy': adminId,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Get old properties (> 3 months) that are still active
  Future<List<PropertyModel>> getOldProperties() async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final snapshot = await _firestore
          .collection(AppConstants.propertiesCollection)
          .where('isArchived', isEqualTo: false)
          .where('status', isEqualTo: 'approved')
          .where('createdAt', isLessThan: threeMonthsAgo.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
// In property_archive_repository.dart

// Get landlord's active properties
Future<List<PropertyModel>> getLandlordProperties(String landlordId) async {
  try {
    print('📥 Getting landlord properties for: $landlordId');
    
    // SIMPLE query first
    final snapshot = await _firestore
        .collection(AppConstants.propertiesCollection)
        .where('landlordId', isEqualTo: landlordId)
        .where('status', isEqualTo: 'approved')
        .get(); // REMOVE orderBy and isArchived filter

    print('✅ Found ${snapshot.docs.length} properties total');
    
    // Filter and sort in memory
    final allProperties = snapshot.docs
        .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    
    // Filter out archived
    final nonArchived = allProperties.where((p) => !p.isArchived).toList();
    
    // Sort by date
    nonArchived.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('✅ Returning ${nonArchived.length} active properties');
    
    return nonArchived;
    
  } catch (e) {
    print('❌ Error in getLandlordProperties: $e');
    rethrow;
  }
}
  // Get landlord's archived properties
  Future<List<PropertyModel>> getLandlordArchivedProperties(String landlordId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.propertiesCollection)
          .where('landlordId', isEqualTo: landlordId)
          .where('isArchived', isEqualTo: true)
          .orderBy('archivedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Restore archived property
  Future<void> restoreProperty(String propertyId) async {
    try {
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(propertyId)
          .update({
            'isArchived': false,
            'archiveReason': null,
            'archivedAt': null,
            'archivedBy': null,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }
}