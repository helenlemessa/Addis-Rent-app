// app_router.dart
import 'package:addis_rent/presentation/screens/auth/forgot_password_screen.dart';
import 'package:addis_rent/presentation/screens/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:addis_rent/presentation/screens/splash_screen.dart';
import 'package:addis_rent/presentation/screens/home/home_screen.dart'; // Use the real one
import 'package:addis_rent/presentation/screens/auth/login_screen.dart';
import 'package:addis_rent/presentation/screens/auth/register_screen.dart';
import 'package:addis_rent/presentation/screens/home/property_list_screen.dart';
import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:addis_rent/presentation/screens/landlord/add_property_screen.dart';
import 'package:addis_rent/presentation/screens/landlord/my_properties_screen.dart';
import 'package:addis_rent/presentation/screens/tenant/favorites_screen.dart';
import 'package:addis_rent/presentation/screens/tenant/search_screen.dart';
import 'package:addis_rent/presentation/screens/admin/admin_dashboard.dart';
import 'package:addis_rent/presentation/screens/admin/approval_screen.dart';
import 'package:addis_rent/presentation/screens/profile/profile_screen.dart';
import 'package:addis_rent/presentation/screens/landlord/landlord_dashboard.dart'; // ADD THIS
import 'package:addis_rent/presentation/screens/admin/property_cleanup_screen.dart';
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String propertyList = '/properties';
  static const String propertyDetail = '/property-detail';
  static const String addProperty = '/add-property';
  static const String myProperties = '/my-properties';
  static const String favorites = '/favorites';
  static const String search = '/search';
  static const String adminDashboard = '/admin-dashboard';
  static const String approval = '/approval';
  static const String profile = '/profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
   static const String landlordDashboard = '/landlord-dashboard';
  static const String propertyCleanup = '/property-cleanup';
  static const String landlordHome = '/landlord-home'; // OPTIONAL
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('📍 AppRouter: Navigating to ${settings.name}');
    
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case propertyList:
        return MaterialPageRoute(builder: (_) => const PropertyListScreen());
        case landlordDashboard:
        return MaterialPageRoute(builder: (_) => const LandlordDashboard());
      case propertyCleanup:
        return MaterialPageRoute(builder: (_) => const PropertyCleanupScreen());
      case propertyDetail:
        final propertyId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(propertyId: propertyId),
        );
      case addProperty:
        return MaterialPageRoute(builder: (_) => const AddPropertyScreen());
      case myProperties:
        return MaterialPageRoute(builder: (_) => const MyPropertiesScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case approval:
        return MaterialPageRoute(builder: (_) => const ApprovalScreen());case forgotPassword:
  return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
case resetPassword:
  final args = settings.arguments as Map<String, dynamic>?;
  return MaterialPageRoute(
    builder: (_) => ResetPasswordScreen(
      resetCode: args?['code'] ?? '',
    ),
  );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}