import 'package:flutter/foundation.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/data/repositories/favorite_repository.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteRepository _repository = FavoriteRepository();
  
  List<PropertyModel> _favoriteProperties = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  bool _isDisposed = false; // Add this flag
  
  List<PropertyModel> get favoriteProperties => _favoriteProperties;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with current user
  void initializeForUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _favoriteIds.clear();
      _favoriteProperties.clear();
      _notifyListenersSafely(); // Use safe method
    }
  }

  Future<void> loadFavorites(String userId) async {
    if (_currentUserId != userId) {
      initializeForUser(userId);
    }
    
    _isLoading = true;
    _notifyListenersSafely();
    
    try {
      final favorites = await _repository.getFavorites(userId);
      _favoriteIds = Set<String>.from(favorites.map((f) => f.propertyId));
      _favoriteProperties = [];
      _error = null;
      print('✅ Loaded ${_favoriteIds.length} favorites for user $userId from Firestore');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading favorites from Firestore: $e');
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  // Load favorite properties with details
  Future<void> loadFavoriteProperties(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _notifyListenersSafely();
    
    try {
      _favoriteProperties = await _repository.getFavoriteProperties(userId);
      _favoriteIds = Set<String>.from(_favoriteProperties.map((p) => p.id));
      _error = null;
      print('✅ Loaded ${_favoriteProperties.length} favorite properties for user $userId');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading favorite properties: $e');
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
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
      _favoriteProperties.removeWhere((p) => p.id == propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }
    _notifyListenersSafely();
    
    try {
      if (wasFavorite) {
        await _repository.removeFavorite(
          userId: userId,
          propertyId: propertyId,
        );
        print('✅ Removed property $propertyId from favorites in Firestore');
      } else {
        await _repository.addFavorite(
          userId: userId,
          propertyId: propertyId,
        );
        print('✅ Added property $propertyId to favorites in Firestore');
      }
      _error = null;
    } catch (e) {
      // Revert UI change on error
      if (wasFavorite) {
        _favoriteIds.add(propertyId);
      } else {
        _favoriteIds.remove(propertyId);
      }
      _notifyListenersSafely();
      
      _error = e.toString();
      print('❌ Error toggling favorite in Firestore: $e');
      rethrow;
    }
  }

  Future<void> checkIfFavorite({
    required String userId,
    required String propertyId,
  }) async {
    try {
      final isFavorite = await _repository.isFavorite(
        userId: userId,
        propertyId: propertyId,
      );
      
      if (_currentUserId != userId) {
        initializeForUser(userId);
      }
      
      if (isFavorite) {
        _favoriteIds.add(propertyId);
      } else {
        _favoriteIds.remove(propertyId);
      }
      
      _notifyListenersSafely();
    } catch (e) {
      _error = e.toString();
      print('❌ Error checking favorite in Firestore: $e');
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
    _notifyListenersSafely();
    
    try {
      await _repository.removeFavorite(
        userId: userId,
        propertyId: propertyId,
      );
      
      _favoriteIds.remove(propertyId);
      _favoriteProperties.removeWhere((p) => p.id == propertyId);
      
      _error = null;
      print('✅ Removed property $propertyId from favorites in Firestore');
      _notifyListenersSafely();
    } catch (e) {
      _error = e.toString();
      print('❌ Error removing favorite from Firestore: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  Future<void> clearFavorites(String userId) async {
    if (_currentUserId != userId) {
      initializeForUser(userId);
    }
    
    _isLoading = true;
    _notifyListenersSafely();
    
    try {
      await _repository.removeAllFavorites(userId);
      _favoriteProperties.clear();
      _favoriteIds.clear();
      
      _error = null;
      print('✅ Cleared all favorites for user $userId from Firestore');
      _notifyListenersSafely();
    } catch (e) {
      _error = e.toString();
      print('❌ Error clearing favorites from Firestore: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _notifyListenersSafely();
    }
  }

  bool isPropertyFavorite(String propertyId) {
    return _favoriteIds.contains(propertyId);
  }

  void clearError() {
    _error = null;
    _notifyListenersSafely();
  }

  void setFavoriteProperties(List<PropertyModel> properties) {
    _favoriteProperties = properties;
    _notifyListenersSafely();
  }

  // SAFE method to notify listeners (checks if disposed)
  void _notifyListenersSafely() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}