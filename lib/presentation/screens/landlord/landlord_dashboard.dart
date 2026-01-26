// Create new file: lib/presentation/screens/landlord/landlord_dashboard.dart
import 'package:addis_rent/presentation/screens/landlord/archived_properties_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/repositories/property_archive_repository.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  final PropertyArchiveRepository _repository = PropertyArchiveRepository();
  List<PropertyModel> _activeProperties = [];
  List<PropertyModel> _archivedProperties = [];
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Active, 1 = Archived

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final landlordId = authProvider.currentUser!.id;
      
      final [active, archived] = await Future.wait([
        _repository.getLandlordProperties(landlordId),
        _repository.getLandlordArchivedProperties(landlordId),
      ]);

      if (mounted) {
        setState(() {
          _activeProperties = active;
          _archivedProperties = archived;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading properties: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRented(PropertyModel property) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Mark as Rented',
      content: 'Mark "${property.title}" as rented/taken?',
      confirmText: 'Mark Rented',
    );

    if (!confirmed) return;

    try {
      await _repository.markAsRented(
        propertyId: property.id,
        landlordId: context.read<AuthProvider>().currentUser!.id,
      );

      await _loadProperties(); // Reload data

      Helpers.showSnackBar(
        context,
        'Property marked as rented',
      );
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error: $e',
        isError: true,
      );
    }
  }

  Future<void> _deleteProperty(PropertyModel property) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Delete Property',
      content: 'Delete "${property.title}"? This will archive the property.',
      confirmText: 'Delete',
    );

    if (!confirmed) return;

    try {
      await _repository.softDeleteProperty(
        propertyId: property.id,
        landlordId: context.read<AuthProvider>().currentUser!.id,
      );

      await _loadProperties(); // Reload data

      Helpers.showSnackBar(
        context,
        'Property deleted successfully',
      );
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error: $e',
        isError: true,
      );
    }
  }

  Future<void> _restoreProperty(PropertyModel property) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Restore Property',
      content: 'Restore "${property.title}"?',
      confirmText: 'Restore',
    );

    if (!confirmed) return;

    try {
      await _repository.restoreProperty(property.id);
      await _loadProperties(); // Reload data

      Helpers.showSnackBar(
        context,
        'Property restored',
      );
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProperties = _selectedTab == 0 ? _activeProperties : _archivedProperties;
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
     // In lib/presentation/screens/landlord/landlord_dashboard.dart
// Update the AppBar:

appBar: AppBar(
  title: const Text('My Properties'),
  actions: [
    // Add this IconButton
    IconButton(
      icon: const Icon(Icons.archive_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ArchivedPropertiesScreen(),
          ),
        );
      },
      tooltip: 'View Archived Properties',
    ),
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadProperties,
    ),
  ],
),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Active (${_activeProperties.length})',
                    0,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Archived (${_archivedProperties.length})',
                    1,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentProperties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTab == 0 ? Icons.home : Icons.archive,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 0 
                                  ? 'No active properties'
                                  : 'No archived properties',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTab == 0
                                  ? 'Post your first property to get started'
                                  : 'Properties you mark as rented or delete will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentProperties.length,
                        itemBuilder: (context, index) {
                          final property = currentProperties[index];
                          return _buildPropertyItem(property);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final isSelected = _selectedTab == tabIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyItem(PropertyModel property) {
    final isArchived = _selectedTab == 1;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          PropertyCard(
            property: property,
            showFavorite: false,
            showStatus: true,
            onTap: () {
              // Navigate to property details
              // You might want to create a read-only detail screen for archived properties
            },
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isArchived ? Colors.grey.shade50 : Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isArchived) ...[
                  // Active property actions
                  OutlinedButton.icon(
                    onPressed: () => _markAsRented(property),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark as Rented'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _deleteProperty(property),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ] else ...[
                  // Archived property info and actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archived: ${property.archiveReason ?? "No reason provided"}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (property.archivedAt != null)
                          Text(
                            'On: ${Helpers.formatDate(property.archivedAt!)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (property.archiveReason != 'Property rented') // Don't allow restoring rented properties
                    OutlinedButton(
                      onPressed: () => _restoreProperty(property),
                      child: const Text('Restore'),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}