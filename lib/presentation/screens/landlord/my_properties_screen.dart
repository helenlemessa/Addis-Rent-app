import 'package:addis_rent/data/repositories/property_archive_repository.dart';
import 'package:addis_rent/presentation/screens/landlord/archived_properties_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/presentation/screens/landlord/add_property_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  String _selectedFilter = 'all';

  void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      propertyProvider.listenToMyProperties(authProvider.currentUser!.id);
    }
  });
}

  void _loadMyProperties() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      propertyProvider.loadMyProperties(authProvider.currentUser!.id);
    }
  }

  List<PropertyModel> _getFilteredProperties(List<PropertyModel> properties) {
    if (_selectedFilter == 'all') return properties;
    return properties.where((p) => p.status == _selectedFilter).toList();
  }

// In lib/presentation/screens/landlord/my_properties_screen.dart
// Update your _showPropertyActions method:

void _showPropertyActions(PropertyModel property, BuildContext context) {
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PropertyDetailScreen(propertyId: property.id),
              ),
            );
          },
        ),
        if (property.status == 'pending' || property.status == 'rejected')
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Property'),
            onTap: () {
              Navigator.pop(context);
              _editProperty(property);
            },
          ),
        // Add "Mark as Rented" option
        if (!property.isArchived && property.status == 'approved')
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark as Rented'),
            onTap: () {
              Navigator.pop(context);
              _markAsRented(property);
            },
          ),
        // Add Archive option for active properties
        if (!property.isArchived)
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive Property'),
            onTap: () {
              Navigator.pop(context);
              _archiveProperty(property);
            },
          ),
        // Add Restore option for archived properties
        if (property.isArchived)
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Property'),
            onTap: () {
              Navigator.pop(context);
              _restoreProperty(property);
            },
          ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete Property',
              style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            _deleteProperty(property);
          },
        ),
      ],
    ),
  );
}

// Add this method for "Mark as Rented"
Future<void> _markAsRented(PropertyModel property) async {
  final confirmed = await Helpers.showConfirmationDialog(
    context,
    title: 'Mark as Rented',
    content: 'Are you sure you want to mark "${property.title}" as rented?',
    confirmText: 'Mark as Rented',
  );

  if (!confirmed) return;

  try {
    final archiveRepository = PropertyArchiveRepository();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser!;
    
    await archiveRepository.markAsRented(
      propertyId: property.id,
      landlordId: user.id,
      reason: 'Property rented',
    );
    
    Helpers.showSnackBar(context, 'Property marked as rented');
    
    // Refresh the list
    final propertyProvider = context.read<PropertyProvider>();
    propertyProvider.listenToMyProperties(user.id);
  } catch (e) {
    Helpers.showSnackBar(context, 'Error marking property as rented: $e', isError: true);
  }
}
// In lib/presentation/screens/landlord/my_properties_screen.dart
// Add these missing methods:

Future<void> _archiveProperty(PropertyModel property) async {
  final confirmed = await Helpers.showConfirmationDialog(
    context,
    title: 'Archive Property',
    content: 'Are you sure you want to archive "${property.title}"?',
    confirmText: 'Archive',
  );

  if (!confirmed) return;

  try {
    final propertyProvider = context.read<PropertyProvider>();
    
    // Check if archiveProperty method exists, otherwise use repository directly
    final archiveRepository = PropertyArchiveRepository();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser!;
    
    await archiveRepository.softDeleteProperty(
      propertyId: property.id,
      landlordId: user.id,
    );
    
    Helpers.showSnackBar(context, 'Property archived');
    
    // Refresh the list
    propertyProvider.listenToMyProperties(user.id);
  } catch (e) {
    Helpers.showSnackBar(context, 'Error archiving property: $e', isError: true);
  }
}

Future<void> _restoreProperty(PropertyModel property) async {
  final confirmed = await Helpers.showConfirmationDialog(
    context,
    title: 'Restore Property',
    content: 'Are you sure you want to restore "${property.title}"?',
    confirmText: 'Restore',
  );

  if (!confirmed) return;

  try {
    final archiveRepository = PropertyArchiveRepository();
    await archiveRepository.restoreProperty(property.id);
    
    Helpers.showSnackBar(context, 'Property restored successfully!');
    
    // Refresh the list
    final propertyProvider = context.read<PropertyProvider>();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      propertyProvider.listenToMyProperties(authProvider.currentUser!.id);
    }
  } catch (e) {
    Helpers.showSnackBar(context, 'Error restoring property: $e', isError: true);
  }
}
  void _editProperty(PropertyModel property) {
    // TODO: Implement edit property screen
    Helpers.showSnackBar(context, 'Edit feature coming soon!');
  }

  Future<void> _deleteProperty(PropertyModel property) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Delete Property',
      content:
          'Are you sure you want to delete this property? This action cannot be undone.',
      confirmText: 'Delete',
    );

    if (confirmed) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      try {
        await propertyProvider.deleteProperty(property.id);
        Helpers.showSnackBar(context, 'Property deleted successfully');
      } catch (e) {
        Helpers.showSnackBar(context, 'Error deleting property: $e',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredProperties =
        _getFilteredProperties(propertyProvider.myProperties);

    return Scaffold(
      appBar: AppBar(
  title: const Text('My Properties'),
  actions: [
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
      icon: const Icon(Icons.add),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddPropertyScreen(),
          ),
        );
      },
    ),
  ],
),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', 'approved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', 'rejected'),
                ],
              ),
            ),
          ),
          // Properties List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadMyProperties();
              },
              child: propertyProvider.isLoading &&
                      propertyProvider.myProperties.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProperties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.apartment,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No properties found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFilter == 'all'
                                    ? 'You haven\'t listed any properties yet'
                                    : 'No $_selectedFilter properties',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddPropertyScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Add Your First Property'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProperties.length,
                          itemBuilder: (context, index) {
                            final property = filteredProperties[index];
                            return GestureDetector(
                              onLongPress: () =>
                                  _showPropertyActions(property, context),
                              child: PropertyCard(
                                property: property,
                                showStatus: true,
                                showFavorite: false, // Landlords don't need favorite button for their own properties
                                isInitiallyFavorite: false, // Add this
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PropertyDetailScreen(
                                        propertyId: property.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
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
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}

 
