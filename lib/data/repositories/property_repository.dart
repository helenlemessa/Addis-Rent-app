import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';
import 'dart:io';
class PropertyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

 Future<List<PropertyModel>> getProperties({
  String? status,
  String? landlordId,
  int limit = 20,
}) async {
  try {
    Query query = _firestore
        .collection(AppConstants.propertiesCollection)
        .where('isArchived', isEqualTo: false) // ADD THIS FILTER
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    if (landlordId != null) {
      query = query.where('landlordId', isEqualTo: landlordId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  } catch (e) {
    rethrow;
  }
}

  Future<String> createProperty(PropertyModel property) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.propertiesCollection)
          .add(property.toMap());
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProperty(PropertyModel property) async {
    try {
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(property.id)
          .update(property.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(propertyId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePropertyStatus({
    required String propertyId,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      
      await _firestore
          .collection(AppConstants.propertiesCollection)
          .doc(propertyId)
          .update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      final urls = <String>[];
      
      for (final path in imagePaths) {
        final fileName = 'properties/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(File(path));
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      rethrow;
    }
  }
// In your existing PropertyRepository, add these methods:

Future<List<PropertyModel>> getActiveProperties({
  String? status,
  String? landlordId,
  int limit = 20,
}) async {
  try {
    Query query = _firestore
        .collection(AppConstants.propertiesCollection)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    if (landlordId != null) {
      query = query.where('landlordId', isEqualTo: landlordId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  } catch (e) {
    rethrow;
  }
}

 
  Future<List<PropertyModel>> searchProperties({
    String? query,
    String? location,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
  }) async {
    try {
      Query firestoreQuery = _firestore
          .collection(AppConstants.propertiesCollection)
          .where('status', isEqualTo: AppConstants.statusApproved);

      if (query != null && query.isNotEmpty) {
        // Note: Firestore doesn't support full-text search
        // For production, consider using Algolia or ElasticSearch
        final properties = await getProperties(status: AppConstants.statusApproved);
        return properties.where((property) {
          return property.title.toLowerCase().contains(query.toLowerCase()) ||
                 property.description.toLowerCase().contains(query.toLowerCase()) ||
                 property.location.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      if (location != null) {
        firestoreQuery = firestoreQuery.where('location', isEqualTo: location);
      }
      
      if (propertyType != null) {
        firestoreQuery = firestoreQuery.where('propertyType', isEqualTo: propertyType);
      }
      
      if (minPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      
      if (maxPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isLessThanOrEqualTo: maxPrice);
      }
      
      if (bedrooms != null) {
        firestoreQuery = firestoreQuery.where('bedrooms', isEqualTo: bedrooms);
      }

      final snapshot = await firestoreQuery.get();
      return snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}