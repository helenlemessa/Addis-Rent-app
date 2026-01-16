// lib/presentation/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:addis_rent/data/models/user_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class UserProvider with ChangeNotifier {
  List<UserModel> _users = [];
  List<UserModel> _landlords = [];
  bool _isLoading = false;
  String? _error;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> get users => _users;
  List<UserModel> get landlords => _landlords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Loading all users...');
      
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      _users = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }).toList();

      _error = null;
      print('✅ Loaded ${_users.length} users');
    } catch (e) {
      _error = 'Failed to load users: $e';
      print('❌ UserProvider error: $_error');
      
      // Fallback mock data
      await _loadMockUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLandlords() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Loading landlords...');
      
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleLandlord)
          .get();

      _landlords = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }).toList();

      _error = null;
      print('✅ Loaded ${_landlords.length} landlords');
    } catch (e) {
      _error = 'Failed to load landlords: $e';
      print('❌ UserProvider error: $_error');
      
      // Filter from users list if available
      if (_users.isNotEmpty) {
        _landlords = _users
            .where((user) => user.role == AppConstants.roleLandlord)
            .toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'role': newRole,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(role: newRole);
      }

      // Update landlords list
      if (newRole == AppConstants.roleLandlord) {
        if (!_landlords.any((user) => user.id == userId)) {
          _landlords.add(_users[userIndex]);
        }
      } else {
        _landlords.removeWhere((user) => user.id == userId);
      }

      _error = null;
      print('✅ Updated user role to $newRole');
    } catch (e) {
      _error = 'Failed to update user role: $e';
      print('❌ updateUserRole error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // In UserProvider class, fix the verifyLandlord method:
Future<void> verifyLandlord(String userId) async {
  _isLoading = true;
  notifyListeners();

  try {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'isVerified': true,
      'verifiedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update local state
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = _users[userIndex].copyWith(
        isVerified: true,
        verifiedAt: DateTime.now(),
      );
    }

    final landlordIndex = _landlords.indexWhere((user) => user.id == userId);
    if (landlordIndex != -1) {
      _landlords[landlordIndex] = _landlords[landlordIndex].copyWith(
        isVerified: true,
        verifiedAt: DateTime.now(),
      );
    }

    _error = null;
    print('✅ Verified landlord: $userId');
  } catch (e) {
    _error = 'Failed to verify landlord: $e';
    print('❌ verifyLandlord error: $_error');
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> suspendUser(String userId, String reason) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isSuspended': true,
        'suspensionReason': reason,
        'suspendedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          isSuspended: true,
          suspensionReason: reason,
        );
      }

      _error = null;
      print('✅ Suspended user: $userId');
    } catch (e) {
      _error = 'Failed to suspend user: $e';
      print('❌ suspendUser error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isSuspended': false,
        'suspensionReason': null,
        'suspendedAt': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          isSuspended: false,
          suspensionReason: null,
        );
      }

      _error = null;
      print('✅ Activated user: $userId');
    } catch (e) {
      _error = 'Failed to activate user: $e';
      print('❌ activateUser error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();

      // Remove from local lists
      _users.removeWhere((user) => user.id == userId);
      _landlords.removeWhere((user) => user.id == userId);

      _error = null;
      print('✅ Deleted user: $userId');
    } catch (e) {
      _error = 'Failed to delete user: $e';
      print('❌ deleteUser error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper: Get user by ID
 // Helper: Get user by ID - add exception handling
UserModel? getUserById(String userId) {
  try {
    return _users.firstWhere((user) => user.id == userId);
  } catch (e) {
    print('⚠️ User not found: $userId');
    return null;
  }
}

  // Mock data for fallback
 // Mock data for fallback - add missing fields
Future<void> _loadMockUsers() async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  final now = DateTime.now();
  _users = [
    UserModel(
      id: '1',
      email: 'admin@addisrent.com',
      fullName: 'Admin User',
      phone: '+251911111111',
      role: AppConstants.roleAdmin,
      isVerified: true,
      isSuspended: false,
      createdAt: now.subtract(const Duration(days: 365)),
      verifiedAt: now.subtract(const Duration(days: 300)),
    ),
    UserModel(
      id: '2',
      email: 'landlord1@example.com',
      fullName: 'Abebe Kebede',
      phone: '+251922222222',
      role: AppConstants.roleLandlord,
      isVerified: true,
      isSuspended: false,
      createdAt: now.subtract(const Duration(days: 180)),
      verifiedAt: now.subtract(const Duration(days: 150)),
    ),
    UserModel(
      id: '3',
      email: 'landlord2@example.com',
      fullName: 'Selamawit T.',
      phone: '+251933333333',
      role: AppConstants.roleLandlord,
      isVerified: false,
      isSuspended: false,
      createdAt: now.subtract(const Duration(days: 90)),
    ),
    UserModel(
      id: '4',
      email: 'tenant1@example.com',
      fullName: 'Mikias H.',
      phone: '+251944444444',
      role: AppConstants.roleTenant,
      isVerified: true,
      isSuspended: false,
      createdAt: now.subtract(const Duration(days: 60)),
      verifiedAt: now.subtract(const Duration(days: 50)),
    ),
    UserModel(
      id: '5',
      email: 'tenant2@example.com',
      fullName: 'Helen G.',
      phone: '+251955555555',
      role: AppConstants.roleTenant,
      isVerified: true,
      isSuspended: false,
      createdAt: now.subtract(const Duration(days: 30)),
      verifiedAt: now.subtract(const Duration(days: 20)),
    ),
  ];
  
  _landlords = _users
      .where((user) => user.role == AppConstants.roleLandlord)
      .toList();
  
  print('⚠️ Using mock user data (${_users.length} users)');
}

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateUserProfile({required String userId, required String fullName, required String phone, String? profileImage}) async {}
}