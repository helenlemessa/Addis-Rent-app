import 'package:flutter/foundation.dart';
import 'package:addis_rent/data/models/property_model.dart';

class FavoriteProvider with ChangeNotifier {
  List<PropertyModel> _favoriteProperties = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  
  List<PropertyModel> get favoriteProperties => _favoriteProperties;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mock favorites for demo
  final Map<String, List<String>> _mockUserFavorites = {
    'demo-user-123': ['1', '2'], // Demo user favorites property 1 and 2
  };

  // Initialize with current user
  void initializeForUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _favoriteIds.clear();
      _favoriteProperties.clear();
      _loadCachedFavorites(userId);
    }
  }

  void _loadCachedFavorites(String userId) {
    final cachedFavorites = _mockUserFavorites[userId] ?? [];
    _favoriteIds = Set<String>.from(cachedFavorites);
    notifyListeners();
  }

  Future<void> loadFavorites(String userId) async {
    if (_currentUserId != userId) {
      initializeForUser(userId);
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get favorite IDs for this user
      final favoriteIds = _mockUserFavorites[userId] ?? [];
      
      // Update the IDs set
      _favoriteIds = Set<String>.from(favoriteIds);
      
      // Clear properties list (in real app, you'd fetch them)
      _favoriteProperties = [];
      
      _error = null;
      print('✅ Loaded ${_favoriteIds.length} favorites for user $userId');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite({
    required String userId,
    required String propertyId,
  }) async {
    if (_currentUserId != userId) {
      initializeForUser(userId);
    }
    
    // Update UI immediately for better UX
    final wasFavorite = _favoriteIds.contains(propertyId);
    if (wasFavorite) {
      _favoriteIds.remove(propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (wasFavorite) {
        // Remove from mock storage
        _mockUserFavorites[userId]?.remove(propertyId);
        print('✅ Removed property $propertyId from favorites');
      } else {
        // Add to mock storage
        if (!_mockUserFavorites.containsKey(userId)) {
          _mockUserFavorites[userId] = [];
        }
        _mockUserFavorites[userId]!.add(propertyId);
        print('✅ Added property $propertyId to favorites');
      }
      
      _error = null;
    } catch (e) {
      // Revert UI change on error
      if (wasFavorite) {
        _favoriteIds.add(propertyId);
      } else {
        _favoriteIds.remove(propertyId);
      }
      notifyListeners();
      
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> checkIfFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check mock storage
      final isFavorite = _mockUserFavorites[userId]?.contains(propertyId) ?? false;
      
      if (_currentUserId != userId) {
        initializeForUser(userId);
      }
      
      if (isFavorite) {
        _favoriteIds.add(propertyId);
      } else {
        _favoriteIds.remove(propertyId);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) async {
    if (_currentUserId != userId) {
      initializeForUser(userId);
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      _favoriteIds.remove(propertyId);
      _mockUserFavorites[userId]?.remove(propertyId);
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> clearFavorites(String userId) async {
    if (_currentUserId != userId) {
      initializeForUser(userId);
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      _favoriteProperties.clear();
      _favoriteIds.clear();
      _mockUserFavorites[userId]?.clear();
      
      _error = null;
      print('✅ Cleared all favorites for user $userId');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  bool isPropertyFavorite(String propertyId) {
    return _favoriteIds.contains(propertyId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get properties from the list of favorite IDs
  void setFavoriteProperties(List<PropertyModel> properties) {
    _favoriteProperties = properties;
    notifyListeners();
  }
}