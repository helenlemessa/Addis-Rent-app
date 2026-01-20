import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:addis_rent/data/models/favorite_model.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class FavoriteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FavoriteModel>> getFavorites(String userId) async {
    try {
      print('🔄 Getting favorites for user: $userId');
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final favorites = snapshot.docs
          .map((doc) => FavoriteModel.fromMap(doc.data(), doc.id))
          .toList();
      
      print('✅ Found ${favorites.length} favorites in Firestore');
      return favorites;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      rethrow;
    }
  }
Future<List<PropertyModel>> getFavoriteProperties(String userId) async {
  try {
    print('🔄 Getting favorite properties for user: $userId');
    
    // 1. Get favorite IDs
    final favorites = await getFavorites(userId);

    if (favorites.isEmpty) {
      print('ℹ️ No favorites found for user $userId');
      return [];
    }

    final propertyIds = favorites.map((f) => f.propertyId).toList();
    print('📋 Favorite property IDs: $propertyIds');

    // 2. Fetch properties - NO WHERE CLAUSE to get ALL matching properties
    final snapshot = await _firestore
        .collection(AppConstants.propertiesCollection)
        .where(FieldPath.documentId, whereIn: propertyIds)
        .get();

    print('📊 Found ${snapshot.docs.length} properties in Firestore');

    // 3. Convert to PropertyModel and filter out archived properties
    final allProperties = snapshot.docs
        .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
        .toList();

    // 4. DEBUG: Print each property's status
    print('\n🔍 PROPERTY DETAILS:');
    for (var property in allProperties) {
      print('🏠 ${property.title} (ID: ${property.id})');
      print('   Status: ${property.status}');
      print('   isArchived: ${property.isArchived}');
      print('   isDeleted: ${property.isDeleted}');
    }

    // 5. Filter out archived properties
    final activeProperties = allProperties.where((property) {
      final isActive = !property.isArchived && property.status == 'approved';
      if (!isActive) {
        print('🚫 Filtering out archived property: ${property.title}');
        print('   Reason: isArchived=${property.isArchived}, status=${property.status}');
      }
      return isActive;
    }).toList();

    print('\n📊 Summary:');
    print('   Total favorites: ${propertyIds.length}');
    print('   Properties found: ${allProperties.length}');
    print('   Active properties: ${activeProperties.length}');
    print('   Archived/Inactive: ${allProperties.length - activeProperties.length}');

    return activeProperties;
  } catch (e) {
    print('❌ Error getting favorite properties: $e');
    rethrow;
  }
}
  Future<void> addFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      print('➕ Adding favorite: user=$userId, property=$propertyId');
      
      // Check if already favorited
      final existing = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      if (existing.docs.isNotEmpty) {
        print('ℹ️ Property already in favorites');
        return;
      }

      await _firestore.collection(AppConstants.favoritesCollection).add({
        'userId': userId,
        'propertyId': propertyId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Favorite added successfully');
    } catch (e) {
      print('❌ Error adding favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      print('➖ Removing favorite: user=$userId, property=$propertyId');
      
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ Favorite not found');
        return;
      }

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Favorite removed successfully');
    } catch (e) {
      print('❌ Error removing favorite: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking favorite: $e');
      return false;
    }
  }

  Future<void> removeAllFavorites(String userId) async {
    try {
      print('🗑️ Removing all favorites for user: $userId');
      
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ All favorites removed successfully');
    } catch (e) {
      print('❌ Error removing all favorites: $e');
      rethrow;
    }
  }
}