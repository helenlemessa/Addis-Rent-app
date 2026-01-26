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
          // DO NOT set isDeleted here!
        });
  } catch (e) {
    rethrow;
  }
}
 // In lib/data/repositories/property_archive_repository.dart

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
          'isDeleted': true,  // ← ADD THIS!
          'archiveReason': reason,
          'archivedAt': DateTime.now().toIso8601String(),
          'deletedAt': DateTime.now().toIso8601String(),
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
// In PropertyArchiveRepository or create a MigrationService

Future<void> fixArchivedProperties() async {
  try {
    print('🔧 Fixing archived properties...');
    
    final snapshot = await _firestore
        .collection(AppConstants.propertiesCollection)
        .where('isArchived', isEqualTo: true)
        .get();
    
    int updatedCount = 0;
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final archiveReason = data['archiveReason'] as String?;
      final isDeleted = data['isDeleted'] as bool? ?? false;
      
      // Update if: archived but not deleted AND not a rented property
      if (isDeleted == false && archiveReason != 'Property rented') {
        await doc.reference.update({
          'isDeleted': true,
          'deletedAt': DateTime.now().toIso8601String(), // ADD THIS
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        updatedCount++;
        print('✅ Fixed property: ${doc.id}');
      }
    }
    
    print('🎉 Done! Fixed ${updatedCount} archived properties');
    
  } catch (e) {
    print('❌ Error fixing archived properties: $e');
  }
}
  // Get old properties (> 3 months) that are still active
  Future<List<PropertyModel>> getOldProperties() async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final snapshot = await _firestore
          .collection(AppConstants.propertiesCollection)
         .where('isArchived', isEqualTo: false)
         .where('isDeleted', isEqualTo: false)
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
// In lib/data/repositories/property_archive_repository.dart
// Add this method:

Future<List<PropertyModel>> getLandlordProperties(String landlordId) async {
    // ONLY ONE COPY OF THIS METHOD
    try {
      final snapshot = await _firestore
          .collection(AppConstants.propertiesCollection)
          .where('landlordId', isEqualTo: landlordId)
          .where('isArchived', isEqualTo: false)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
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
            'rentedAt': null,
            'archivedAt': null,
            'archivedBy': null,
            'updatedAt': DateTime.now().toIso8601String(),
            'isDeleted': false,
          });
    } catch (e) {
      rethrow;
    }
  }
}