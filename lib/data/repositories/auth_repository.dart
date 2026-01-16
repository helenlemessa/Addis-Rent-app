// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:addis_rent/data/models/user_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // CHANGE ONLY THIS LINE to use the old constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // DO NOT CHANGE ANYTHING ELSE BELOW THIS LINE
  // Your existing code is already correct
  
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      
      if (user.providerData.any((info) => info.providerId == 'google.com')) {
        final userModel = UserModel(
          id: user.uid,
          fullName: user.displayName ?? 'Google User',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          role: 'tenant',
          profileImage: user.photoURL,
          isVerified: true,
          isSuspended: false,
          suspensionReason: null,
          suspendedAt: null,
          verifiedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }
Future<UserModel> register({
  required String fullName,
  required String email,
  required String phone,
  required String password,
  required String role,
}) async {
  print('\n📝 ========== AUTH REPOSITORY REGISTER ==========');
  print('📧 Email: $email');
  print('👤 Full Name: $fullName');
  print('📱 Phone: $phone');
  print('🎭 Role: $role');
  print('🔑 Password length: ${password.length}');
  
  try {
    // 1. Check if user already exists in Firestore
    print('\n🔍 Step 1: Checking if user already exists...');
    
    final emailQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    
    if (emailQuery.docs.isNotEmpty) {
      print('❌ User already exists with this email!');
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'An account already exists with this email',
      );
    }
    
    // 2. Create Firebase Auth user
    print('\n🔄 Step 2: Creating Firebase Auth user...');
    
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Firebase Auth user created!');
      print('   - UID: ${credential.user!.uid}');
    } on FirebaseAuthException catch (authError) {
      print('❌ Firebase Auth error:');
      print('   - Code: ${authError.code}');
      print('   - Message: ${authError.message}');
      
      if (authError.code == 'email-already-in-use') {
        print('⚠️ Email already in use in Firebase Auth');
        
        // Try to sign in instead
        print('🔄 Attempting to sign in instead...');
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Signed in to existing account');
      } else {
        rethrow;
      }
    }
    
    // 3. Create user document in Firestore
    print('\n📄 Step 3: Creating user document in Firestore...');
    
    final userModel = UserModel(
      id: credential.user!.uid,
      fullName: fullName.trim(),
      email: email.toLowerCase().trim(),
      phone: phone.trim(),
      role: role,
      profileImage: null,
      isVerified: role == 'admin',
      isSuspended: false,
      suspensionReason: null,
      suspendedAt: null,
      verifiedAt: role == 'admin' ? DateTime.now() : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userModel.toMap());
      print('✅ User document created in Firestore!');
    } catch (firestoreError) {
      print('❌ Firestore error: $firestoreError');
      
      // If Firestore fails, delete the Firebase Auth user
      print('🔄 Deleting Firebase Auth user due to Firestore error...');
      await credential.user!.delete();
      rethrow;
    }
    
    print('\n🎉 REGISTRATION SUCCESSFUL!');
    print('👤 User: ${userModel.fullName}');
    print('📧 Email: ${userModel.email}');
    print('🎭 Role: ${userModel.role}');
    print('🆔 ID: ${userModel.id}');
    print('========================================\n');
    
    return userModel;
    
  } catch (e) {
    print('❌ Registration error: $e');
    print('========================================\n');
    rethrow;
  }
}

  Future<UserModel> login({
  required String email,
  required String password,
}) async {
  print('\n🔐 ========== AUTH REPOSITORY LOGIN ==========');
  print('📧 Email: $email');
  print('🔑 Password: ***** (length: ${password.length})');
  
  try {
    // 1. First, check if user exists in Firestore
    print('🔍 Step 1: Checking if user exists in Firestore...');
    
    final querySnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      print('✅ User found in Firestore:');
      final doc = querySnapshot.docs.first;
      print('   - User ID: ${doc.id}');
      print('   - Full Name: ${doc.data()['fullName']}');
      print('   - Role: ${doc.data()['role']}');
    } else {
      print('❌ User NOT found in Firestore with email: $email');
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found with this email',
      );
    }
    
    // 2. Try Firebase Auth login
    print('\n🔄 Step 2: Attempting Firebase Auth login...');
    
    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Firebase Auth login successful!');
      print('   - Firebase User ID: ${credential.user?.uid}');
      print('   - Email verified: ${credential.user?.emailVerified}');
    } on FirebaseAuthException catch (authError) {
      print('❌ Firebase Auth error:');
      print('   - Code: ${authError.code}');
      print('   - Message: ${authError.message}');
      
      // Provide specific error messages
      switch (authError.code) {
        case 'invalid-credential':
        case 'wrong-password':
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Incorrect password',
          );
        case 'user-not-found':
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No account found with this email',
          );
        case 'user-disabled':
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'This account has been disabled',
          );
        case 'too-many-requests':
          throw FirebaseAuthException(
            code: 'too-many-requests',
            message: 'Too many attempts. Try again later',
          );
        default:
          rethrow;
      }
    }
    
    // 3. Get user data from Firestore
    print('\n📄 Step 3: Getting user data from Firestore...');
    
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .get();

    if (!doc.exists) {
      print('❌ User document not found in Firestore after login!');
      print('   - Firebase UID: ${credential.user!.uid}');
      print('   - User email: ${credential.user!.email}');
      
      // Try to find by email instead
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        print('⚠️ Found user by email, but UID mismatch!');
        print('   - Firestore ID: ${querySnapshot.docs.first.id}');
        print('   - Firebase UID: ${credential.user!.uid}');
        
        // This indicates the user was created with a different Firebase account
        throw FirebaseAuthException(
          code: 'uid-mismatch',
          message: 'Account exists with different credentials',
        );
      }
      
      throw Exception('User not found in database after login');
    }

    print('✅ User document found, creating UserModel...');
    final userModel = UserModel.fromMap(doc.data()!, doc.id);
    
    print('\n🎉 LOGIN SUCCESSFUL!');
    print('👤 User: ${userModel.fullName}');
    print('📧 Email: ${userModel.email}');
    print('🎭 Role: ${userModel.role}');
    print('🆔 ID: ${userModel.id}');
    
    return userModel;
    
  } catch (e) {
    print('❌ AuthRepository.login error:');
    print('   - Error: $e');
    print('   - Type: ${e.runtimeType}');
    print('========================================\n');
    rethrow;
  }
}

  Future<UserModel> loginWithGoogle() async {
    try {
      // REMOVE THE initialize() CALL - not needed
      // await _googleSignIn.initialize(
      //   scopes: ['email', 'profile'],
      // );
      
      await _googleSignIn.signOut();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!, userDoc.id);
      } else {
        final userModel = UserModel(
          id: user.uid,
          fullName: googleUser.displayName ?? 'Google User',
          email: googleUser.email,
          phone: user.phoneNumber ?? '',
          role: 'tenant',
          profileImage: user.photoURL,
          isVerified: true,
          isSuspended: false,
          suspensionReason: null,
          suspendedAt: null,
          verifiedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('❌ Logout error: $e');
      rethrow;
    }
  }
  
  Future<void> createAdminUser() async {
    try {
      final adminEmail = 'admin@demo.com';
      final adminPassword = 'Admin123!';
      
      print('🔄 Creating admin user with email: $adminEmail');
      
      UserCredential authResult = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      
      print('✅ Firebase Auth user created: ${authResult.user!.uid}');
      
      await FirebaseFirestore.instance
        .collection('users')
        .doc(authResult.user!.uid)
        .set({
          'id': authResult.user!.uid,
          'email': adminEmail,
          'fullName': 'Admin User',
          'phone': '+251911111111',
          'role': 'admin',
          'isVerified': true,
          'isSuspended': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      
      print('✅ Admin user created successfully!');
      print('📧 Login with: $adminEmail');
      print('🔑 Password: $adminPassword');
      
    } catch (e) {
      print('❌ Error creating admin: $e');
      
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        print('⚠️ Admin user already exists in Firebase Auth');
        print('🔍 Checking Firestore for admin document...');
        
        final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: 'admin@demo.com')
          .limit(1)
          .get();
        
        if (snapshot.docs.isNotEmpty) {
          print('✅ Admin user exists in Firestore');
          print('📋 Admin data: ${snapshot.docs.first.data()}');
        }
      }
    }
  }
  
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['fullName'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (profileImage != null) updateData['profileImage'] = profileImage;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      print('❌ Update profile error: $e');
      rethrow;
    }
  }
}