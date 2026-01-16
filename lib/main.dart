// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/core/app_router.dart';
import 'package:addis_rent/core/theme/app_theme.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/providers/favorite_provider.dart';
import 'package:addis_rent/presentation/providers/user_provider.dart';

// Import the generated firebase_options.dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting AddisRent app...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // CREATE ADMIN USER
    await createAdminUserDirectly();
    
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

Future<void> createAdminUserDirectly() async {
  try {
    print('\n🔄 CHECKING/CREATING ADMIN USER...');
    
    final adminEmail = 'admin@addisrent.com';
    final adminPassword = 'Admin123!';
    
    // Check if admin already exists in Firestore
    final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: adminEmail)
      .limit(1)
      .get();
    
    if (snapshot.docs.isNotEmpty) {
      print('✅ Admin user already exists in Firestore');
      print('📋 Admin data: ${snapshot.docs.first.data()}');
      return;
    }
    
    print('🔄 No admin found, creating one...');
    
    try {
      // Try to create user in Firebase Auth
      final authResult = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      
      print('✅ Created in Firebase Auth: ${authResult.user!.uid}');
      
      // Create user document in Firestore
      await FirebaseFirestore.instance
        .collection('users')
        .doc(authResult.user!.uid)
        .set({
          'id': authResult.user!.uid,
          'email': adminEmail,
          'fullName': 'System Administrator',
          'phone': '+251911111111',
          'role': 'admin',
          'isVerified': true,
          'isSuspended': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      
      print('✅ Admin user created successfully!');
      print('📧 Login with: $adminEmail');
      print('🔑 Password: $adminPassword');
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️ Admin email already exists in Firebase Auth');
        
        // Try to sign in to get the UID
        try {
          final signInResult = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
          
          print('✅ Signed in, UID: ${signInResult.user!.uid}');
          
          // Now create the Firestore document
          await FirebaseFirestore.instance
            .collection('users')
            .doc(signInResult.user!.uid)
            .set({
              'id': signInResult.user!.uid,
              'email': adminEmail,
              'fullName': 'System Administrator',
              'phone': '+251911111111',
              'role': 'admin',
              'isVerified': true,
              'isSuspended': false,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true)); // Use merge to not overwrite if exists
          
          print('✅ Admin Firestore document created/updated');
          
          // Sign out after creating
          await FirebaseAuth.instance.signOut();
          
        } catch (signInError) {
          print('❌ Could not sign in: $signInError');
          print('💡 You need to reset the password in Firebase Console');
        }
      } else {
        print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      }
    }
    
  } catch (e) {
    print('❌ Error in createAdminUserDirectly: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (_) => PropertyProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => FavoriteProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProvider(), lazy: true),
      ],
      child: MaterialApp(
        title: 'AddisRent',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        // Use the router system you already have
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
        navigatorKey: GlobalKey<NavigatorState>(),
        // Don't set home when using initialRoute
      ),
    );
  }
}

// Add this extension method to help with property loading
extension PropertyLoader on BuildContext {
  void initUserData() {
    final authProvider = Provider.of<AuthProvider>(this, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(this, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null && user.role == 'landlord') {
      print('👤 Initializing property data for landlord: ${user.fullName}');
      // Load this landlord's properties
      propertyProvider.listenToMyProperties(user.id);
    }
  }
}