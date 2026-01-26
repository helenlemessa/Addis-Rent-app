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
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

Future<void> handlePasswordResetLink(BuildContext context, Uri link) async {
  final queryParams = link.queryParameters;
  final mode = queryParams['mode'];
  final oobCode = queryParams['oobCode'];

  if (mode == 'resetPassword' && oobCode != null) {
    Navigator.pushNamed(
      context,
      AppRouter.resetPassword,
      arguments: {'code': oobCode},
    );
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
      child: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  var _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized) return;
      _initialized = true;

      // Ensure PropertyProvider is created and run the migration/initialization
      try {
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        await propertyProvider.initializeIsDeletedField();
        print('✅ initializeIsDeletedField completed');
      } catch (e) {
        print('⚠️ initializeIsDeletedField error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
