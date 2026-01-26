// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:addis_rent/data/models/user_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';
import 'package:addis_rent/core/errors/auth_errors.dart';
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
  print('\n🔐 ========== LOGIN ATTEMPT ==========');
  print('📧 Email: $email');
  
  UserCredential credential;
  
  try {
    // 1. Firebase Auth login
    credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    print('✅ Firebase Auth successful: ${credential.user!.uid}');
    
  } on FirebaseAuthException catch (e) {
    print('❌ ======== FIREBASE AUTH ERROR DETAILS ========');
    print('Error Code: "${e.code}"');
    print('Error Message: "${e.message}"');
    print('==============================================');
    
    // Get user-friendly message
    final errorMessage = AuthErrorHandler.getFirebaseAuthErrorMessage(e.code);
    print('Translated to user message: "$errorMessage"');
    
    throw Exception(errorMessage);
  } catch (e) {
    print('❌ ======== NON-FIREBASE ERROR DETAILS ========');
    print('Error Type: ${e.runtimeType}');
    print('Error: $e');
    print('==============================================');
    
    // Get user-friendly message
    final errorMessage = AuthErrorHandler.getGenericErrorMessage(e);
    print('Translated to user message: "$errorMessage"');
    
    throw Exception(errorMessage);
  }
  
  // From here down, we know Firebase login was successful
  try {
    // 2. Get user document from Firestore
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .get();

    // 3. If document doesn't exist, create it
    if (!doc.exists) {
      print('⚠️ User document missing in Firestore, creating one...');
      
      // Check if user exists by email (might have different UID)
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // User exists with different UID (Google sign-in maybe)
        print('⚠️ Found user with same email but different UID');
        final existingDoc = querySnapshot.docs.first;
        final existingData = existingDoc.data();
        
        // Merge data
        final userModel = UserModel(
          id: credential.user!.uid, // Use new UID
          fullName: existingData['fullName'] ?? credential.user!.displayName ?? email.split('@').first,
          email: email.toLowerCase(),
          phone: existingData['phone'] ?? '',
          role: existingData['role'] ?? 'tenant',
          profileImage: existingData['profileImage'] ?? credential.user!.photoURL,
          isVerified: existingData['isVerified'] ?? true,
          isSuspended: existingData['isSuspended'] ?? false,
          suspensionReason: existingData['suspensionReason'],
          suspendedAt: existingData['suspendedAt'] != null ? 
              (existingData['suspendedAt'] is Timestamp ? 
               existingData['suspendedAt'].toDate() : 
               DateTime.parse(existingData['suspendedAt'])) : null,
          verifiedAt: existingData['verifiedAt'] != null ?
              (existingData['verifiedAt'] is Timestamp ? 
               existingData['verifiedAt'].toDate() : 
               DateTime.parse(existingData['verifiedAt'])) : null,
          createdAt: existingData['createdAt'] != null ?
              (existingData['createdAt'] is Timestamp ? 
               existingData['createdAt'].toDate() : 
               DateTime.parse(existingData['createdAt'])) : DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save with correct UID
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toMap());
        
        // Delete old document if UID is different
        if (existingDoc.id != credential.user!.uid) {
          await existingDoc.reference.delete();
          print('🗑️ Deleted old document with different UID');
        }
        
        print('✅ User document created/fixed');
        return userModel;
      } else {
        // Brand new user - create document
        final userModel = UserModel(
          id: credential.user!.uid,
          fullName: credential.user!.displayName ?? email.split('@').first,
          email: email.toLowerCase(),
          phone: credential.user!.phoneNumber ?? '',
          role: 'tenant', // Default role
          profileImage: credential.user!.photoURL,
          isVerified: credential.user!.emailVerified,
          isSuspended: false,
          suspensionReason: null,
          suspendedAt: null,
          verifiedAt: credential.user!.emailVerified ? DateTime.now() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toMap());
        
        print('✅ New user document created');
        return userModel;
      }
    }

    // 4. Document exists - parse it
    print('✅ User document exists, parsing...');
    
    try {
      final userModel = UserModel.fromMap(doc.data()!, doc.id);
      print('✅ UserModel created successfully');
      return userModel;
    } catch (e) {
      print('❌ Error parsing UserModel: $e');
      print('🔄 Attempting to fix corrupted user data...');
      
      // Try to fix the data
      return await _fixCorruptedUser(doc, credential.user!, email);
    }
    
  } catch (e) {
    print('❌ Error after Firebase login (Firestore/user processing): $e');
    throw Exception('Login successful, but there was an error loading your profile. Please try again.');
  }
}

Future<UserModel> _fixCorruptedUser(
  DocumentSnapshot doc, 
  User firebaseUser, 
  String email
) async {
  try {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Create a clean user model with fallbacks
    final userModel = UserModel(
      id: doc.id,
      fullName: data['fullName']?.toString().trim() ?? 
               firebaseUser.displayName ?? 
               email.split('@').first,
      email: (data['email'] ?? email).toString().toLowerCase().trim(),
      phone: data['phone']?.toString().trim() ?? firebaseUser.phoneNumber ?? '',
      role: data['role']?.toString().toLowerCase() ?? 'tenant',
      profileImage: data['profileImage']?.toString() ?? firebaseUser.photoURL,
      isVerified: data['isVerified'] == true,
      isSuspended: data['isSuspended'] == true,
      suspensionReason: data['suspensionReason']?.toString(),
      suspendedAt: null, // Reset for safety
      verifiedAt: null,  // Reset for safety
      createdAt: _parseFirestoreDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Save fixed data back to Firestore
    await doc.reference.set(userModel.toMap(), SetOptions(merge: true));
    
    print('✅ Fixed corrupted user data for: ${userModel.email}');
    return userModel;
    
  } catch (e) {
    print('❌ Could not fix user: $e');
    
    // Last resort: create minimal user
    return UserModel(
      id: doc.id,
      fullName: email.split('@').first,
      email: email.toLowerCase(),
      phone: '',
      role: 'tenant',
      profileImage: null,
      isVerified: false,
      isSuspended: false,
      suspensionReason: null,
      suspendedAt: null,
      verifiedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

DateTime? _parseFirestoreDate(dynamic dateValue) {
  if (dateValue == null) return null;
  
  try {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
  } catch (e) {
    print('⚠️ Date parse error: $dateValue - $e');
  }
  
  return null;
}
Future<UserModel> loginWithGoogle() async {
  print('\n🔐 ========== GOOGLE SIGN-IN ATTEMPT ==========');
  
  try {
    // 1. Initialize Google Sign-In with proper configuration
    print('🔄 Step 1: Initializing Google Sign-In...');
    
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // IMPORTANT: Add serverClientId for web support
      scopes: ['email', 'profile'],
      signInOption: SignInOption.standard,
      // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // Optional
    );
    
    // 2. Sign out first to clear any cached credentials
    print('🔄 Step 2: Signing out from any previous session...');
    await googleSignIn.signOut();
    
    // 3. Start Google Sign-In process
    print('🔄 Step 3: Starting Google Sign-In UI...');
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      print('❌ Google Sign-In was cancelled by user');
      throw Exception('Google Sign-In was cancelled');
    }
    
    print('✅ Google Sign-In UI completed');
    print('   👤 User: ${googleUser.displayName}');
    print('   📧 Email: ${googleUser.email}');
    
    // 4. Get authentication details
    print('🔄 Step 4: Getting authentication tokens...');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    print('✅ Authentication tokens received');
    print('   Access Token: ${googleAuth.accessToken != null ? "Yes" : "No"}');
    print('   ID Token: ${googleAuth.idToken != null ? "Yes" : "No"}');
    
    // 5. Create Firebase credential
    print('🔄 Step 5: Creating Firebase credential...');
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // 6. Sign in to Firebase with Google credential
    print('🔄 Step 6: Signing in to Firebase...');
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    
    print('✅ Firebase sign-in successful');
    print('   Firebase User ID: ${userCredential.user!.uid}');
    print('   Email: ${userCredential.user!.email}');
    print('   Display Name: ${userCredential.user!.displayName}');
    print('   Photo URL: ${userCredential.user!.photoURL}');
    
    // 7. Check if user exists in Firestore
    print('🔄 Step 7: Checking Firestore for user document...');
    
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userCredential.user!.uid)
        .get();
    
    UserModel userModel;
    
    if (userDoc.exists) {
      print('✅ User document found in Firestore');
      userModel = UserModel.fromMap(userDoc.data()!, userDoc.id);
      print('   User Role: ${userModel.role}');
    } else {
      print('⚠️ User document not found, creating new one...');
      
      // Create new user model
      userModel = UserModel(
        id: userCredential.user!.uid,
        fullName: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        phone: userCredential.user!.phoneNumber ?? '',
        role: 'tenant', // Default role for Google sign-in
        profileImage: userCredential.user!.photoURL,
        isVerified: true, // Google users are verified
        isSuspended: false,
        suspensionReason: null,
        suspendedAt: null,
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());
      
      print('✅ New user document created');
    }
    
    print('\n🎉 GOOGLE SIGN-IN SUCCESSFUL!');
    print('👤 User: ${userModel.fullName}');
    print('📧 Email: ${userModel.email}');
    print('🎭 Role: ${userModel.role}');
    print('🆔 ID: ${userModel.id}');
    
    return userModel;
    
  } on FirebaseAuthException catch (e) {
    print('❌ Firebase Auth Exception:');
    print('   Code: ${e.code}');
    print('   Message: ${e.message}');
    print('   Email: ${e.email}');
    print('   Credential: ${e.credential}');
    
    // Provide better error messages
    String errorMessage = 'Google Sign-In failed';
    
    switch (e.code) {
      case 'account-exists-with-different-credential':
        errorMessage = 'This email is already registered with a different sign-in method.';
        break;
      case 'invalid-credential':
        errorMessage = 'Invalid Google credentials. Please try again.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Google Sign-In is not enabled. Contact support.';
        break;
      case 'user-disabled':
        errorMessage = 'This account has been disabled.';
        break;
      case 'user-not-found':
        errorMessage = 'No account found. Please sign up first.';
        break;
      case 'wrong-password':
        errorMessage = 'Invalid credentials.';
        break;
      case 'invalid-verification-code':
        errorMessage = 'Invalid verification code.';
        break;
      case 'invalid-verification-id':
        errorMessage = 'Invalid verification ID.';
        break;
    }
    
    throw Exception(errorMessage);
    
  } catch (e) {
    print('❌ General Google Sign-In error:');
    print('   Error: $e');
    print('   Type: ${e.runtimeType}');
    
    // Check for platform-specific errors
    if (e.toString().contains('ApiException: 10')) {
      print('⚠️ This is a DEVELOPER_ERROR (ApiException: 10)');
      print('💡 Likely causes:');
      print('   1. Wrong SHA-1 fingerprint in Firebase Console');
      print('   2. Missing Web Client ID');
      print('   3. Google Sign-In not enabled in Firebase Console');
      print('   4. Incorrect package name in Firebase Console');
      throw Exception('Google Sign-In configuration error. Check Firebase setup.');
    }
    
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
  
   // In lib/data/repositories/auth_repository.dart, add these methods:

Future<void> sendPasswordResetEmail(String email) async {
  print('\n🔄 ========== PASSWORD RESET REQUEST ==========');
  print('📧 Email: $email');
  
  try {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: ActionCodeSettings(
        url: 'https://addisrent-d27f4.firebaseapp.com/__/auth/action', // Your Firebase Dynamic Link
        handleCodeInApp: true,
         
      ),
    );
    
    print('✅ Password reset email sent successfully');
  } on FirebaseAuthException catch (e) {
    print('❌ Firebase error sending reset email:');
    print('   Code: ${e.code}');
    print('   Message: ${e.message}');
    
    String errorMessage = 'Failed to send reset email';
    
    switch (e.code) {
      case 'invalid-email':
        errorMessage = 'Invalid email address';
        break;
      case 'user-not-found':
        errorMessage = 'No account found with this email';
        break;
      case 'user-disabled':
        errorMessage = 'This account has been disabled';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later';
        break;
    }
    
    throw Exception(errorMessage);
  } catch (e) {
    print('❌ General error sending reset email: $e');
    rethrow;
  }
}

Future<void> confirmPasswordReset({
  required String code,
  required String newPassword,
}) async {
  print('\n🔄 ========== PASSWORD RESET CONFIRMATION ==========');
  
  try {
    await _auth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
    
    print('✅ Password reset confirmed successfully');
  } on FirebaseAuthException catch (e) {
    print('❌ Firebase error confirming password reset:');
    print('   Code: ${e.code}');
    print('   Message: ${e.message}');
    
    String errorMessage = 'Failed to reset password';
    
    switch (e.code) {
      case 'expired-action-code':
        errorMessage = 'Reset code has expired';
        break;
      case 'invalid-action-code':
        errorMessage = 'Invalid reset code';
        break;
      case 'weak-password':
        errorMessage = 'Password is too weak';
        break;
    }
    
    throw Exception(errorMessage);
  } catch (e) {
    print('❌ General error confirming password reset: $e');
    rethrow;
  }
}

Future<void> verifyPasswordResetCode(String code) async {
  print('\n🔄 ========== VERIFYING RESET CODE ==========');
  
  try {
    final email = await _auth.verifyPasswordResetCode(code);
    print('✅ Reset code verified for email: $email');
  } on FirebaseAuthException catch (e) {
    print('❌ Firebase error verifying reset code:');
    print('   Code: ${e.code}');
    print('   Message: ${e.message}');
    
    String errorMessage = 'Invalid reset code';
    
    switch (e.code) {
      case 'expired-action-code':
        errorMessage = 'Reset code has expired';
        break;
      case 'invalid-action-code':
        errorMessage = 'Invalid reset code';
        break;
    }
    
    throw Exception(errorMessage);
  } catch (e) {
    print('❌ General error verifying reset code: $e');
    rethrow;
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