// lib/presentation/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:addis_rent/data/models/user_model.dart';
import 'package:addis_rent/data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;


  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;


  Future<void> initialize() async {
    if (_initialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.getCurrentUser();
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        print('✅ User already logged in: ${user.fullName} (${user.role})');
      } else {
        _currentUser = null;
        _isLoggedIn = false;
        print('✅ No user logged in');
      }

      _error = null;
      _initialized = true;
    } catch (e) {
      _error = 'Initialization failed: $e';
      print('❌ AuthProvider error: $_error');
      _currentUser = null;
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _isLoggedIn = true;
      _error = null;

      print('✅ Email login successful: ${user.fullName} (${user.role})');
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      print('❌ Login error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.loginWithGoogle();

      _currentUser = user;
      _isLoggedIn = true;
      _error = null;

      print('✅ Google login successful: ${user.fullName} (${user.role})');
    } catch (e) {
      _error = 'Google login failed: ${e.toString()}';
      print('❌ Google login error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      _currentUser = user;
      _isLoggedIn = true;
      _error = null;

      print('✅ Registration successful: ${user.fullName} (${user.role})');
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      print('❌ Registration error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear local state
      _currentUser = null;
      _isLoggedIn = false; // FIXED: Changed from _isAuthenticated to _isLoggedIn
      _initialized = false; // Reset initialization so it checks again
      
      // Clear any local storage/cache
      await _clearLocalStorage();
      
      print('✅ User logged out successfully');
    } catch (e) {
      _error = 'Logout failed: $e';
      print('❌ Logout error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.updateProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        phone: phone,
        profileImage: profileImage,
      );

      // Update local user
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        phone: phone ?? _currentUser!.phone,
        profileImage: profileImage ?? _currentUser!.profileImage,
      );

      _error = null;
      print('✅ Profile updated');
    } catch (e) {
      _error = 'Profile update failed: ${e.toString()}';
      print('❌ Profile update error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  Future<void> _clearLocalStorage() async {
    // You can add any local storage clearing logic here
    // For example: SharedPreferences, Hive, etc.
    print('🔄 Clearing local storage...');
  }

  // Remove the setter since it's not needed
  // set _isAuthenticated(bool _isAuthenticated) {}
}