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

  final List<BottomNavigationBarItem> _tenantNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: 'Favorites',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  final List<BottomNavigationBarItem> _landlordNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Browse',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.apartment),
      label: 'My Properties',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  final List<BottomNavigationBarItem> _adminNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('current user role: ${auth.currentUser?.role}');

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isLandlord = auth.currentUser?.role == 'landlord';
    if (isLandlord) showAddButtons();

    final isAdmin = user.role == 'admin';
    final isTenant = user.role == 'tenant';

    return Scaffold(
      appBar: AppBar(
    
        // ADD THIS: Show Add Property button for landlords on My Properties tab
        actions: isLandlord && _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
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
              ]
            : null,
      ),
      body: _getCurrentScreen(user.role),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: isAdmin
            ? _adminNavItems
            : isLandlord
                ? _landlordNavItems
                : _tenantNavItems,
      ),
      // ADD THIS: Floating Action Button for landlords to add properties
      floatingActionButton: isLandlord && _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPropertyScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Add New Property',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
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
      return ['Home', 'Search', 'Favorites', 'Profile'][index];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void showAddButtons() {
    // This method can be used to trigger any additional UI updates
    // or logic needed to show the add buttons for landlords.
    setState(() {});
  }
}
