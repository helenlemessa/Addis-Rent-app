import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:addis_rent/data/models/favorite_model.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class FavoriteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FavoriteModel>> getFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              FavoriteModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PropertyModel>> getFavoriteProperties(String userId) async {
    try {
      final favorites = await getFavorites(userId);

      if (favorites.isEmpty) return [];

      final propertyIds = favorites.map((f) => f.propertyId).toList();

      final snapshot = await _firestore
          .collection(AppConstants.propertiesCollection)
          .where('id', whereIn: propertyIds)
          .get();

      return snapshot.docs
          .map((doc) =>
              PropertyModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      // Check if already favorited
      final existing = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      if (existing.docs.isNotEmpty) return;

      await _firestore.collection(AppConstants.favoritesCollection).add({
        'userId': userId,
        'propertyId': propertyId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      if (snapshot.docs.isEmpty) return;

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
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
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeAllFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
