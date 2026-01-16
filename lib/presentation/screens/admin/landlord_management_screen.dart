// lib/presentation/screens/admin/landlord_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/user_provider.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/models/user_model.dart';

class LandlordManagementScreen extends StatefulWidget {
  const LandlordManagementScreen({super.key});

  @override
  State<LandlordManagementScreen> createState() => _LandlordManagementScreenState();
}

class _LandlordManagementScreenState extends State<LandlordManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, verified, unverified, suspended

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLandlords();
    });
  }

  void _loadLandlords() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.loadLandlords();
  }

  List<UserModel> _getFilteredLandlords(List<UserModel> landlords) {
    var filtered = landlords;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((landlord) {
        return landlord.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            landlord.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            landlord.phone.contains(_searchQuery);
      }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'verified':
        filtered = filtered.where((landlord) => landlord.isVerified).toList();
        break;
      case 'unverified':
        filtered = filtered.where((landlord) => !landlord.isVerified).toList();
        break;
      case 'suspended':
        filtered = filtered.where((landlord) => landlord.isSuspended).toList();
        break;
    }

    return filtered;
  }

  Future<void> _verifyLandlord(UserModel landlord) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Verify Landlord',
      content: 'Are you sure you want to verify ${landlord.fullName}?',
      confirmText: 'Verify',
      confirmColor: Colors.green,
    );

    if (confirmed) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        await userProvider.verifyLandlord(landlord.id);
        Helpers.showSnackBar(context, 'Landlord verified successfully');
      } catch (e) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _suspendLandlord(UserModel landlord) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Landlord'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reason for suspension:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (result == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        await userProvider.suspendUser(
          landlord.id,
          reasonController.text.trim(),
        );
        Helpers.showSnackBar(context, 'Landlord suspended');
      } catch (e) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _activateLandlord(UserModel landlord) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Activate Landlord',
      content: 'Are you sure you want to activate ${landlord.fullName}?',
      confirmText: 'Activate',
      confirmColor: Colors.green,
    );

    if (confirmed) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        await userProvider.activateUser(landlord.id);
        Helpers.showSnackBar(context, 'Landlord activated');
      } catch (e) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  void _showLandlordDetails(UserModel landlord) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildLandlordDetails(landlord),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final filteredLandlords = _getFilteredLandlords(userProvider.landlords);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landlord Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLandlords,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search landlords...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Verified', 'verified'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unverified', 'unverified'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspended', 'suspended'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Landlords List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadLandlords(),
              child: userProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLandlords.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No landlords found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredLandlords.length,
                          itemBuilder: (context, index) {
                            final landlord = filteredLandlords[index];
                            return _buildLandlordCard(landlord);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildLandlordCard(UserModel landlord) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            landlord.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          landlord.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(landlord.email),
            Text(landlord.phone),
            const SizedBox(height: 4),
            _buildStatusBadges(landlord),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showLandlordActions(landlord),
        ),
        onTap: () => _showLandlordDetails(landlord),
      ),
    );
  }

  Widget _buildStatusBadges(UserModel landlord) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (landlord.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (landlord.isSuspended)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Suspended',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (!landlord.isVerified && !landlord.isSuspended)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Unverified',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showLandlordActions(UserModel landlord) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.remove_red_eye),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _showLandlordDetails(landlord);
            },
          ),
          if (!landlord.isVerified && !landlord.isSuspended)
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Verify Landlord'),
              onTap: () {
                Navigator.pop(context);
                _verifyLandlord(landlord);
              },
            ),
          if (!landlord.isSuspended)
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Suspend Landlord'),
              onTap: () {
                Navigator.pop(context);
                _suspendLandlord(landlord);
              },
            ),
          if (landlord.isSuspended)
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Activate Landlord'),
              onTap: () {
                Navigator.pop(context);
                _activateLandlord(landlord);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLandlordDetails(UserModel landlord) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                landlord.fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Name', landlord.fullName),
          _buildDetailRow('Email', landlord.email),
          _buildDetailRow('Phone', landlord.phone),
          _buildDetailRow('Role', landlord.role.toUpperCase()),
          _buildDetailRow('Status', landlord.isSuspended
              ? 'Suspended'
              : landlord.isVerified
                  ? 'Verified'
                  : 'Unverified'),
          if (landlord.isVerified)
            _buildDetailRow(
                'Verified on', Helpers.formatDate(landlord.verifiedAt!)),
          if (landlord.isSuspended)
            _buildDetailRow(
                'Suspended on', Helpers.formatDate(landlord.suspendedAt!)),
          if (landlord.suspensionReason != null)
            _buildDetailRow('Suspension Reason', landlord.suspensionReason!),
          _buildDetailRow(
              'Joined', Helpers.formatDate(landlord.createdAt)),
          const SizedBox(height: 20),
          if (!landlord.isVerified && !landlord.isSuspended)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _verifyLandlord(landlord);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified),
                  SizedBox(width: 8),
                  Text('Verify Landlord'),
                ],
              ),
            ),
          if (landlord.isSuspended)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _activateLandlord(landlord);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle),
                  SizedBox(width: 8),
                  Text('Activate Landlord'),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}