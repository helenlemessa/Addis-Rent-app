import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/providers/user_provider.dart';
import 'package:addis_rent/presentation/screens/admin/approval_screen.dart';
import 'package:addis_rent/presentation/screens/admin/landlord_management_screen.dart';
import 'package:addis_rent/presentation/widgets/empty_state.dart';
import 'package:addis_rent/core/utils/helpers.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    propertyProvider.listenToAllProperties(); // Admin sees everything
    userProvider.loadUsers();
    userProvider.loadLandlords();
  }

  Widget _buildStatsCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyStatusChart() {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final properties = propertyProvider.properties;
    
    final pendingCount = properties.where((p) => p.status == 'pending').length;
    final approvedCount = properties.where((p) => p.status == 'approved').length;
    final rejectedCount = properties.where((p) => p.status == 'rejected').length;
    final total = properties.length;

    if (total == 0) {
      return const Center(
        child: Text('No properties yet'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Status Overview',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Status Bars
          _buildStatusBar(
            label: 'Pending',
            count: pendingCount,
            total: total,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatusBar(
            label: 'Approved',
            count: approvedCount,
            total: total,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusBar(
            label: 'Rejected',
            count: rejectedCount,
            total: total,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Properties',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                total.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: percentage * 3, // Assuming max width of 300
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final recentProperties = propertyProvider.properties.take(5).toList();

    if (recentProperties.isEmpty) {
      return const Center(
        child: Text('No recent activities'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...recentProperties.map((property) {
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(property.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      property.status == 'approved'
                          ? Icons.check_circle
                          : property.status == 'pending'
                              ? Icons.access_time
                              : Icons.cancel,
                      color: Helpers.getStatusColor(property.status),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    property.title,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${property.location} • ${Helpers.formatDate(property.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(property.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Navigate to property detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailScreen(
                          propertyId: property.id,
                        ),
                      ),
                    );
                  },
                ),
                if (property != recentProperties.last)
                  const Divider(height: 1, color: Colors.grey),
              ],
            );
          }),
        ],
      ),
    );
  }

  // We need to import PropertyDetailScreen
  // Add this import at the top of your file
  // import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final pendingCount = propertyProvider.properties
        .where((p) => p.status == 'pending')
        .length;
    final landlordCount = userProvider.landlords.length;
    final userCount = userProvider.users.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: propertyProvider.isLoading || userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Admin!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage properties, users, and approvals',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quick Stats
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatsCard(
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        title: 'Pending Properties',
                        value: pendingCount.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApprovalScreen(),
                            ),
                          );
                        },
                      ),
                      _buildStatsCard(
                        icon: Icons.people,
                        color: Colors.blue,
                        title: 'Total Landlords',
                        value: landlordCount.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LandlordManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _buildStatsCard(
                        icon: Icons.group,
                        color: Colors.purple,
                        title: 'Total Users',
                        value: userCount.toString(),
                        onTap: () {
                          // Create a UserManagementScreen similar to LandlordManagementScreen
                          _showUsersManagement(context);
                        },
                      ),
                      _buildStatsCard(
                        icon: Icons.apartment,
                        color: Colors.green,
                        title: 'Total Properties',
                        value: propertyProvider.properties.length.toString(),
                        onTap: () {
                          _showAllProperties(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Property Status Chart
                  _buildPropertyStatusChart(),
                  const SizedBox(height: 24),
                  // Recent Activities
                  _buildRecentActivities(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showUsersManagement(BuildContext context) {
    // You can create a UserManagementScreen similar to LandlordManagementScreen
    // For now, let's show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Users Management'),
        content: const Text('User management screen is under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAllProperties(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final properties = propertyProvider.properties;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Properties',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips for property status
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'Approved', 'Rejected']
                    .map((status) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: false,
                      onSelected: (selected) {
                        // Implement filtering
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: properties.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No properties found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final property = properties[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Helpers.getStatusColor(property.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              property.status == 'approved'
                                  ? Icons.check_circle
                                  : property.status == 'pending'
                                      ? Icons.access_time
                                      : Icons.cancel,
                              color: Helpers.getStatusColor(property.status),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${property.location} • ${property.formattedPrice}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Helpers.getStatusColor(property.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDetailScreen(
                                  propertyId: property.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// You need to create a UserManagementScreen similar to LandlordManagementScreen
// Here's a basic version you can create in a new file


 

// Also, you need to make sure PropertyDetailScreen is imported
// Add this import at the top of the file:
// import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';