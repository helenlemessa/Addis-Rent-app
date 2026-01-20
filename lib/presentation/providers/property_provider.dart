// lib/presentation/providers/property_provider.dart
import 'dart:async';
import 'package:addis_rent/core/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:addis_rent/data/models/property_model.dart';

class PropertyProvider with ChangeNotifier {
  List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  List<PropertyModel> _myProperties = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  String? _error;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions for real-time updates
  StreamSubscription? _allPropertiesSubscription;
  StreamSubscription? _myPropertiesSubscription;
  StreamSubscription? _approvedPropertiesSubscription;

  // Filters
  String _searchQuery = '';
  String? _selectedLocation;
  String? _selectedType;
  double? _minPrice;
  double? _maxPrice;
  int? _selectedBedrooms;

  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get filteredProperties => _filteredProperties;
  List<PropertyModel> get myProperties => _myProperties;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get unique locations from ALL properties (not just filtered)
  List<String> get uniqueLocations {
    if (_properties.isEmpty) return [];
    final locations = _properties.map((p) => p.location).toSet().toList();
    locations.sort();
    return locations;
  }

  // Get unique property types from ALL properties
  List<String> get uniquePropertyTypes {
    if (_properties.isEmpty) return [];
    final types = _properties.map((p) => p.propertyType).toSet().toList();
    types.sort();
    return types;
  }

  // Get available bedroom counts from ALL properties
  List<int> get availableBedrooms {
    if (_properties.isEmpty) return [];
    final bedrooms = _properties.map((p) => p.bedrooms).toSet().toList();
    bedrooms.sort();
    return bedrooms.where((b) => b > 0).toList();
  }

  // Get filter summary for UI
  String get filterSummary {
    final parts = [];
    if (_searchQuery.isNotEmpty) parts.add('Search: "$_searchQuery"');
    if (_selectedLocation != null) parts.add('Location: $_selectedLocation');
    if (_selectedType != null) parts.add('Type: $_selectedType');
    if (_selectedBedrooms != null) parts.add('Bedrooms: $_selectedBedrooms');
    if (_minPrice != null || _maxPrice != null) {
      parts.add('Price: ${_minPrice ?? 0} - ${_maxPrice ?? "∞"} ETB');
    }
    return parts.isEmpty ? 'No filters applied' : parts.join(' • ');
  }

  // ================== REAL-TIME LISTENERS ==================

  // For Admin: Listen to ALL properties
void listenToAllProperties() {
  _clearSubscriptions();
  
  _allPropertiesSubscription = _firestore
      .collection('properties')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snapshot) {
    _handlePropertySnapshot(snapshot, 'total');
  }, onError: (error) {
    _error = 'Real-time error: $error';
    print('❌ Real-time listener error: $error');
    notifyListeners();
  });
}

  // For Tenant Browse: Listen to APPROVED properties only
void listenToApprovedProperties() {
  _clearSubscriptions();
  
  print('🎯 Starting listenToApprovedProperties()');
  
  // Use SIMPLE query first (no composite filters)
  _approvedPropertiesSubscription = _firestore
      .collection('properties')
      .where('status', isEqualTo: 'approved')
      .snapshots() // REMOVE orderBy and isArchived filter for now
      .listen((snapshot) {
    
    print('📥 Received ${snapshot.docs.length} approved properties');
    
    // Process in memory
    final allProperties = snapshot.docs.map((doc) {
      return PropertyModel.fromMap(
        doc.data()! as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    
    // 1. Filter out archived properties
    final nonArchived = allProperties.where((p) => !p.isArchived).toList();
    print('✅ Non-archived properties: ${nonArchived.length}');
    
    // 2. Sort by date manually
    nonArchived.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _properties = nonArchived;
    _filterProperties();
    
    print('🎯 Final properties: ${_properties.length}');
    print('🎯 Filtered properties: ${_filteredProperties.length}');
    
    notifyListeners();
    
  }, onError: (error) {
    print('🔥 listenToApprovedProperties error: $error');
    _error = 'Error: $error';
    notifyListeners();
  });
}
void listenToMyProperties(String landlordId) {
  _clearSubscriptions();
  
  print('👤 Starting listenToMyProperties() for landlord: $landlordId');
  
  // Use SIMPLE query
  _myPropertiesSubscription = _firestore
      .collection('properties')
      .where('landlordId', isEqualTo: landlordId)
      .snapshots() // REMOVE orderBy and isArchived filter
      .listen((snapshot) {
    
    print('📥 Received ${snapshot.docs.length} properties for landlord');
    
    final allProperties = snapshot.docs.map((doc) {
      return PropertyModel.fromMap(
        doc.data()! as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    
    // Filter and sort in memory
    final nonArchived = allProperties.where((p) => !p.isArchived).toList();
    nonArchived.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _myProperties = nonArchived;
    
    print('✅ Landlord active properties: ${_myProperties.length}');
    
    notifyListeners();
  }, onError: (error) {
    print('🔥 listenToMyProperties error: $error');
    _error = 'Error: $error';
    notifyListeners();
  });
}

  void _handlePropertySnapshot(QuerySnapshot snapshot, String type) {
    _properties = snapshot.docs.map((doc) {
      return PropertyModel.fromMap(
        doc.data()! as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    
    // Apply existing filters to new data
    _filterProperties();
    
    notifyListeners();
  }

  void _clearSubscriptions() {
    _allPropertiesSubscription?.cancel();
    _myPropertiesSubscription?.cancel();
    _approvedPropertiesSubscription?.cancel();
  }

  // ================== CRUD OPERATIONS ==================

  Future<void> createProperty(PropertyModel property) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Upload images to Cloudinary
      final List<String> imageUrls = await CloudinaryService.uploadImages(property.images);
      
      if (imageUrls.isEmpty) {
        throw Exception('No images were uploaded successfully');
      }
      
      // 2. Create property with Cloudinary URLs
      final propertyDocRef = _firestore.collection('properties').doc();
      final propertyId = propertyDocRef.id;
      
      final newProperty = property.copyWith(
        id: propertyId,
        landlordId: user.uid,
        landlordEmail: user.email ?? property.landlordEmail,
        images: imageUrls,
        createdAt: DateTime.now(),
      );
      
      // 3. Save to Firestore
      await propertyDocRef.set(newProperty.toMap());
      
    } catch (e) {
      _error = 'Failed to create property: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePropertyStatus({
    required String propertyId,
    required String status,
    String? rejectionReason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection('properties')
          .doc(propertyId)
          .update(updateData);

    } catch (e) {
      _error = 'Failed to update property status: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .delete();

    } catch (e) {
      _error = 'Failed to delete property: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================== LOAD INDIVIDUAL PROPERTY ==================

  Future<void> loadProperty(String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .get();

      if (doc.exists) {
        _selectedProperty = PropertyModel.fromMap(
          doc.data()! as Map<String, dynamic>,
          doc.id,
        );
      } else {
        _selectedProperty = null;
        _error = 'Property not found';
      }
    } catch (e) {
      _error = 'Failed to load property: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================== FILTER METHODS ==================

  void applyFilters({
    String? query,
    String? location,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
  }) {
    _searchQuery = query ?? _searchQuery;
    _selectedLocation = location;
    _selectedType = propertyType;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _selectedBedrooms = bedrooms;

    _filterProperties();
    notifyListeners();
    
    print('🔍 Filters applied:');
    print('   Query: $_searchQuery');
    print('   Location: $_selectedLocation');
    print('   Type: $_selectedType');
    print('   Price: $_minPrice - $_maxPrice');
    print('   Bedrooms: $_selectedBedrooms');
    print('   Results: ${_filteredProperties.length}');
  }

 void _filterProperties() {
  if (_searchQuery.isEmpty &&
      _selectedLocation == null &&
      _selectedType == null &&
      _minPrice == null &&
      _maxPrice == null &&
      _selectedBedrooms == null) {
    // Filter out archived properties
    _filteredProperties = _properties.where((p) => !p.isArchived).toList();
    return;
  }

    _filteredProperties = _properties.where((property) {
       if (property.isArchived) return false;
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchesQuery =
            property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                property.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                property.location
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
        if (!matchesQuery) return false;
      }

      // Location filter
      if (_selectedLocation != null && property.location != _selectedLocation) {
        return false;
      }

      // Property type filter
      if (_selectedType != null && property.propertyType != _selectedType) {
        return false;
      }

      // Price filter
      if (_minPrice != null && property.price < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && property.price > _maxPrice!) {
        return false;
      }

      // Bedrooms filter
      if (_selectedBedrooms != null && property.bedrooms != _selectedBedrooms) {
        return false;
      }

      return true;
    }).toList();
  }
void listenToPendingProperties() {
  _clearSubscriptions();
  
  _allPropertiesSubscription = _firestore
      .collection('properties')
      .where('status', isEqualTo: 'pending')
      .snapshots() // REMOVE orderBy
      .listen((snapshot) {
    _handlePropertySnapshot(snapshot, 'pending');
  }, onError: (error) {
    _error = 'Real-time error: $error';
    print('❌ Pending properties listener error: $error');
    notifyListeners();
  });
}
  void clearFilters() {
    _searchQuery = '';
    _selectedLocation = null;
    _selectedType = null;
    _minPrice = null;
    _maxPrice = null;
    _selectedBedrooms = null;

    _filteredProperties = List.from(_properties);
    notifyListeners();
    
    print('🧹 All filters cleared');
  }

  // Search method for home page
  void search(String query) {
    _searchQuery = query.trim();
    _filterProperties();
    notifyListeners();
  }

  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ================== DEPRECATED METHODS (for compatibility) ==================

  void loadProperties({required String status}) {
    if (status == 'approved') {
      listenToApprovedProperties();
    } else if (status == 'pending') {
      listenToPendingProperties();
    } else {
      listenToAllProperties();
    }
  }

  void loadMyProperties(String id) {
    listenToMyProperties(id);
  }
}