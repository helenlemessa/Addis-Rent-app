import 'package:addis_rent/core/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/presentation/screens/landlord/landlord_dashboard.dart';
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            accountName: Text(user?.fullName ?? 'Guest'),
            accountEmail: Text(user?.email ?? 'Not logged in'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                Helpers.getInitials(user?.fullName ?? 'GU'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (user?.role == 'tenant') ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to home
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.search,
                    title: 'Search',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to search
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.favorite,
                    title: 'Favorites',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to favorites
                    },
                  ),
                ],
                if (user?.role == 'landlord') ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'My Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.landlordDashboard);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.apartment,
                    title: 'My Properties',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.myProperties);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_circle,
                    title: 'Add New Property',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.addProperty);
                    },
                  ),
                ],
                
                // ADMIN SPECIFIC
                if (user?.role == 'admin') ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Admin Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.adminDashboard);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.approval,
                    title: 'Pending Approvals',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.approval);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'Landlord Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.adminDashboard);
                      // You might want to create a specific screen for this
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.clean_hands,
                    title: 'Cleanup Old Properties',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.propertyCleanup);
                    },
                  ),
                ],
               const Divider(),
                
                // PROFILE & SETTINGS (Common for all)
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.profile);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Add settings screen navigation
                    Helpers.showSnackBar(context, 'Settings coming soon');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Add help screen navigation
                    Helpers.showSnackBar(context, 'Help coming soon');
                  },
                ),
                
                const Divider(),
                
                // LOGOUT
                if (authProvider.isLoggedIn)
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      await authProvider.logout();
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                  ),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'AddisRent v1.0.0',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}