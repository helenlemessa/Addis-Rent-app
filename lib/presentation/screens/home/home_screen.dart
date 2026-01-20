import 'package:addis_rent/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/screens/home/property_list_screen.dart';
import 'package:addis_rent/presentation/screens/landlord/add_property_screen.dart';
import 'package:addis_rent/presentation/screens/landlord/my_properties_screen.dart';
import 'package:addis_rent/presentation/screens/tenant/favorites_screen.dart';
import 'package:addis_rent/presentation/screens/tenant/search_screen.dart';
import 'package:addis_rent/presentation/screens/profile/profile_screen.dart';
import 'package:addis_rent/presentation/screens/admin/admin_dashboard.dart';
import 'package:addis_rent/presentation/screens/landlord/landlord_dashboard.dart'; // ADD THIS IMPORT
import 'package:addis_rent/core/app_router.dart'; // ADD THIS IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tenantScreens = [
    const PropertyListScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _landlordScreens = [
    const PropertyListScreen(),
    const MyPropertiesScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _adminScreens = [
    const AdminDashboard(),
    const ProfileScreen(),
  ];

  // Enhanced navigation items with better icons and colors
  final List<Map<String, dynamic>> _tenantNavData = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_filled,
      'label': 'Home',
      'color': Colors.blue,
    },
    {
      'icon': Icons.search_outlined,
      'activeIcon': Icons.search,
      'label': 'Search',
      'color': Colors.green,
    },
    {
      'icon': Icons.favorite_outlined,
      'activeIcon': Icons.favorite,
      'label': 'Favorites',
      'color': Colors.pink,
    },
    {
      'icon': Icons.person_outlined,
      'activeIcon': Icons.person,
      'label': 'Profile',
      'color': Colors.purple,
    },
  ];

  final List<Map<String, dynamic>> _landlordNavData = [
    {
      'icon': Icons.explore_outlined,
      'activeIcon': Icons.explore,
      'label': 'Browse',
      'color': Colors.blue,
    },
    {
      'icon': Icons.apartment_outlined,
      'activeIcon': Icons.apartment,
      'label': 'My Properties',
      'color': Colors.orange,
    },
    {
      'icon': Icons.person_outlined,
      'activeIcon': Icons.person,
      'label': 'Profile',
      'color': Colors.purple,
    },
  ];

  final List<Map<String, dynamic>> _adminNavData = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard,
      'label': 'Dashboard',
      'color': Colors.indigo,
    },
    {
      'icon': Icons.person_outlined,
      'activeIcon': Icons.person,
      'label': 'Profile',
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isLandlord = user.role == 'landlord';
    final isAdmin = user.role == 'admin';

    return Scaffold(
      appBar: _buildAppBar(user, authProvider), // UPDATED: Pass authProvider
      body: _getCurrentScreen(user.role),
      bottomNavigationBar: _buildCustomNavigationBar(user.role),
      floatingActionButton: _buildFloatingActionButton(isLandlord),
    );
  }

  // UPDATED: Add authProvider parameter
  AppBar _buildAppBar(UserModel user, AuthProvider authProvider) {
    String title = _getAppBarTitle(_selectedIndex, user.role);
    
    return AppBar(
      title: Row(
        children: [
          // Using a more visible container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, // SOLID color, not transparent
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getAppBarIcon(user.role),
              color: Colors.white, // White icon on colored background
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // FIXED: Using Expanded to prevent overflow
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black87, // Dark text for good contrast
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      elevation: 3, // Increased elevation for more shadow
      shadowColor: Colors.black.withOpacity(0.15),
      backgroundColor: Colors.white, // Solid white background
      foregroundColor: Colors.black87, // Dark icons/text
      iconTheme: const IconThemeData(color: Colors.black87), // Dark back button
      actions: [
        // ADD DASHBOARD BUTTONS HERE
        if (user.role == 'landlord' && _selectedIndex != 1) // Show only when NOT on My Properties screen
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.dashboard,
                color: Colors.blue.shade700,
                size: 22,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.landlordDashboard);
            },
            tooltip: 'Landlord Dashboard',
          ),
        
        if (user.role == 'admin' && _selectedIndex != 0) // Show only when NOT on Admin Dashboard
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.purple.shade700,
                size: 22,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.adminDashboard);
            },
            tooltip: 'Admin Dashboard',
          ),
        
        // EXISTING ADD PROPERTY BUTTON
        if (user.role == 'landlord' && _selectedIndex == 1)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPropertyScreen(),
                  ),
                );
              },
              tooltip: 'Add New Property',
            ),
          ),
      ],
    );
  }

  // Helper method to get appropriate icon based on user role
  IconData _getAppBarIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'landlord':
        return Icons.apartment;
      default:
        return Icons.home;
    }
  }

  Widget _buildCustomNavigationBar(String role) {
    List<Map<String, dynamic>> navData;
    
    if (role == 'admin') {
      navData = _adminNavData;
    } else if (role == 'landlord') {
      navData = _landlordNavData;
    } else {
      navData = _tenantNavData;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navData.length, (index) {
          final item = navData[index];
          final isSelected = _selectedIndex == index;
          
          return GestureDetector(
            onTap: () => _onItemTapped(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(minWidth: 60),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (item['color'] as Color).withOpacity(0.15) // Slightly more opaque
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item['activeIcon'] : item['icon'],
                    color: isSelected 
                        ? item['color'] as Color
                        : Colors.grey.shade700, // Darker grey for better visibility
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, // Medium weight for non-selected
                      color: isSelected 
                          ? item['color'] as Color
                          : Colors.grey.shade700, // Darker grey
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget? _buildFloatingActionButton(bool isLandlord) {
    if (isLandlord && _selectedIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPropertyScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Add Property',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );
    }
    return null;
  }

  Widget _getCurrentScreen(String role) {
    if (role == 'admin') {
      return _adminScreens[_selectedIndex];
    } else if (role == 'landlord') {
      return _landlordScreens[_selectedIndex];
    } else {
      return _tenantScreens[_selectedIndex];
    }
  }

  String _getAppBarTitle(int index, String role) {
    if (role == 'admin') {
      return ['Admin Dashboard', 'Profile'][index];
    } else if (role == 'landlord') {
      return ['Browse Properties', 'My Properties', 'Profile'][index];
    } else {
      return ['Discover Rentals', 'Search', 'My Favorites', 'Profile'][index];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}