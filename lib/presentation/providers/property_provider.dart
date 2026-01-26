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
// In PropertyProvider class
String get searchQuery => _searchQuery;  // Add this public getter
// In PropertyProvider class
bool get hasActiveSearch => _searchQuery.isNotEmpty;
bool get hasActiveFilters => 
    _searchQuery.isNotEmpty ||
    _selectedLocation != null ||
    _selectedType != null ||
    _minPrice != null ||
    _maxPrice != null ||
    _selectedBedrooms != null;

void resetToDefault() {
  // Only reset if we have active filters
  if (hasActiveFilters) {
    clearFilters();
  }
}
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

void listenToAllProperties() {
  _clearSubscriptions();
  
  print('👑 Starting listenToAllProperties() for admin');
  
  // Get ALL properties first, then filter in memory
  _allPropertiesSubscription = _firestore
      .collection('properties')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snapshot) {
    
    print('📥 Received ${snapshot.docs.length} total properties');
    
    final allProperties = snapshot.docs.map((doc) {
      return PropertyModel.fromMap(
        doc.data()! as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    
    // Filter out deleted properties in memory
    // This handles both missing isDeleted field and isDeleted = true
    final nonDeletedProperties = allProperties.where((p) => !p.isDeleted).toList();
    
    print('✅ Non-deleted properties: ${nonDeletedProperties.length}');
    
    // Debug: List all properties with their isDeleted status
    allProperties.forEach((p) {
      print('🔍 ${p.id} - Title: "${p.title}" - isDeleted: ${p.isDeleted} - isArchived: ${p.isArchived}');
    });
    
    _properties = nonDeletedProperties;
    _filterProperties();
    
    print('🎯 Final admin properties: ${_properties.length}');
    
    notifyListeners();
  }, onError: (error) {
    print('🔥 listenToAllProperties error: $error');
    _error = 'Real-time error: $error';
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
  print('🗑️ Clearing subscriptions:');
  print('   _allPropertiesSubscription: ${_allPropertiesSubscription != null}');
  print('   _myPropertiesSubscription: ${_myPropertiesSubscription != null}');
  print('   _approvedPropertiesSubscription: ${_approvedPropertiesSubscription != null}');
  
  _allPropertiesSubscription?.cancel();
  _myPropertiesSubscription?.cancel();
  _approvedPropertiesSubscription?.cancel();
  
  _allPropertiesSubscription = null;
  _myPropertiesSubscription = null;
  _approvedPropertiesSubscription = null;
  
  print('✅ All subscriptions cleared');
}
Future<void> initializeIsDeletedField() async {
  try {
    print('🔧 Initializing isDeleted field for all properties...');
    
    final snapshot = await _firestore.collection('properties').get();
    int updatedCount = 0;
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // If isDeleted field doesn't exist
      if (!data.containsKey('isDeleted')) {
        await doc.reference.update({
          'isDeleted': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        updatedCount++;
        print('✅ Added isDeleted to property: ${doc.id}');
      }
    }
    
    print('🎉 Done! Updated ${updatedCount} properties');
    
  } catch (e) {
    print('❌ Error initializing isDeleted: $e');
  }
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
    // Check if property is pending
    final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
    final isPending = propertyDoc.exists && (propertyDoc.data()?['status'] == 'pending');
    
    if (isPending) {
      // SOFT DELETE for pending properties - mark as deleted
      await _firestore.collection('properties').doc(propertyId).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      // HARD DELETE for other properties
      await _firestore.collection('properties').doc(propertyId).delete();
    }

    // Update local state
    _properties.removeWhere((p) => p.id == propertyId);
    _filteredProperties.removeWhere((p) => p.id == propertyId);
    _myProperties.removeWhere((p) => p.id == propertyId);

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

void applyFilters({
  String? query,
  String? location,
  String? propertyType,
  double? minPrice,
  double? maxPrice,
  int? bedrooms,
}) {
  // Debug what we're receiving
  print('🔍 applyFilters() called with:');
  print('   query: "$query"');
  print('   location: $location');
  print('   propertyType: $propertyType');
  
  // FIX: Always update search query when query parameter is provided
  // Even if it's an empty string!
  if (query != null) {
    _searchQuery = query;
    print('✅ Updated _searchQuery to: "$_searchQuery"');
  } else {
    print('ℹ️ No query provided, keeping: "$_searchQuery"');
  }
  
  _selectedLocation = location;
  _selectedType = propertyType;
  _minPrice = minPrice;
  _maxPrice = maxPrice;
  _selectedBedrooms = bedrooms;

  _filterProperties();
  notifyListeners();
  
  print('🔍 Filtered results: ${_filteredProperties.length}');
}

void _filterProperties() {
  print('🔍 Starting _filterProperties()');
  print('   Search query: "$_searchQuery"');
  print('   Total properties: ${_properties.length}');
  
  // Always start by filtering out archived properties first
  final List<PropertyModel> activeProperties = 
      _properties.where((p) => !p.isArchived && !p.isDeleted).toList();
  
  print('   Active properties (non-archived,non-deleted): ${activeProperties.length}');
  
  if (_searchQuery.isEmpty &&
      _selectedLocation == null &&
      _selectedType == null &&
      _minPrice == null &&
      _maxPrice == null &&
      _selectedBedrooms == null) {
    // No filters, just show all active properties
    _filteredProperties = activeProperties;
    print('   No filters, showing ${_filteredProperties.length} active properties');
    return;
  }

  // Apply all other filters to active properties
  _filteredProperties = activeProperties.where((property) {
    bool passesAllFilters = true;
    
    // Search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery =
          property.title.toLowerCase().contains(query) ||
          property.description.toLowerCase().contains(query) ||
          property.location.toLowerCase().contains(query);
      
      if (!matchesQuery) {
        passesAllFilters = false;
      }
    }

    // Location filter
    if (passesAllFilters && _selectedLocation != null) {
      if (property.location.toLowerCase() != _selectedLocation!.toLowerCase()) {
        passesAllFilters = false;
      }
    }

    // Property type filter
    if (passesAllFilters && _selectedType != null) {
      if (property.propertyType.toLowerCase() != _selectedType!.toLowerCase()) {
        passesAllFilters = false;
      }
    }

    // Price filter
    if (passesAllFilters && _minPrice != null) {
      if (property.price < _minPrice!) {
        passesAllFilters = false;
      }
    }
    
    if (passesAllFilters && _maxPrice != null) {
      if (property.price > _maxPrice!) {
        passesAllFilters = false;
      }
    }

    // Bedrooms filter
    if (passesAllFilters && _selectedBedrooms != null) {
      if (property.bedrooms != _selectedBedrooms) {
        passesAllFilters = false;
      }
    }

    return passesAllFilters;
  }).toList();
  
  print('   Filtered properties: ${_filteredProperties.length}');
}
  // In lib/presentation/providers/property_provider.dart
// Add this method to your PropertyProvider class:

Future<void> archiveProperty({
  required String propertyId,
  required String reason,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Update property in Firestore
    await _firestore
        .collection('properties')
        .doc(propertyId)
        .update({
          'isArchived': true,
          'archiveReason': reason,
          'archivedAt': DateTime.now().toIso8601String(),
          'archivedBy': user.uid,
          'updatedAt': DateTime.now().toIso8601String(),
        });

    // Update local state
    _properties.removeWhere((p) => p.id == propertyId);
    _filteredProperties.removeWhere((p) => p.id == propertyId);
    _myProperties.removeWhere((p) => p.id == propertyId);

  } catch (e) {
    _error = 'Failed to archive property: $e';
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
void listenToPendingProperties() {
  _clearSubscriptions();
  
  _allPropertiesSubscription = _firestore
      .collection('properties')
      .where('status', isEqualTo: 'pending')
      .where('isDeleted', isNotEqualTo: true) // Keep this
      .snapshots()
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

  _filterProperties(); // <-- CORRECT! Call the filter method
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