import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/core/app_router.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    _initialized = true;
    
    print('🚀 SplashScreen: Initializing app...');
    
    try {
      // Initialize auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      
      // Add a small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      // Check if user is logged in
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        print('📍 User logged in, loading data...');
        
        final user = authProvider.currentUser!;
        
        // Load properties
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        propertyProvider.loadProperties(status: 'approved');
        
        print('✅ Navigation to home...');
        Navigator.pushReplacementNamed(context, AppRouter.home);
      } else {
        print('📍 No user logged in, navigating to login...');
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } catch (e) {
      print('⚠️ Error during initialization: $e');
      
      if (mounted) {
        // On error, navigate to login
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // FIX: Prevent overflow
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.apartment,
                  size: 60,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'AddisRent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find Your Perfect Home',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isLoading) {
                    return const Text(
                      'Checking authentication...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Hide when not loading
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}