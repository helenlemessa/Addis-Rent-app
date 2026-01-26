import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/data/repositories/property_archive_repository.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/models/property_model.dart';

class ArchivedPropertiesScreen extends StatefulWidget {
  const ArchivedPropertiesScreen({super.key});

  @override
  State<ArchivedPropertiesScreen> createState() => _ArchivedPropertiesScreenState();
}

class _ArchivedPropertiesScreenState extends State<ArchivedPropertiesScreen> {
  final PropertyArchiveRepository _archiveRepository = PropertyArchiveRepository();
  List<PropertyModel> _archivedProperties = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArchivedProperties();
  }

  Future<void> _loadArchivedProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      
      if (user != null) {
        final properties = await _archiveRepository.getLandlordArchivedProperties(user.id);
        
        if (mounted) {
          setState(() {
            _archivedProperties = properties;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
      print('❌ Error loading archived properties: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    setState(() {
      _isLoading = true;
    });

    try {
      await _archiveRepository.restoreProperty(property.id);
      
      // Remove from local list
      if (mounted) {
        setState(() {
          _archivedProperties.removeWhere((p) => p.id == property.id);
        });
      }

      // Show success message
      Helpers.showSnackBar(context, 'Property restored successfully!');
      
    } catch (e) {
      Helpers.showSnackBar(context, 'Error restoring property: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getArchiveReasonText(PropertyModel property) {
    if (property.archiveReason == 'Property rented') {
      return 'Marked as Rented';
    } else if (property.archiveReason == 'Landlord deleted') {
      return 'Deleted by Landlord';
    } else if (property.archiveReason?.contains('Admin cleanup') == true) {
      return 'Cleaned by Admin';
    } else {
      return property.archiveReason ?? 'Archived';
    }
  }

  Color _getArchiveReasonColor(PropertyModel property) {
    if (property.archiveReason == 'Property rented') {
      return Colors.green;
    } else if (property.archiveReason == 'Landlord deleted') {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArchivedProperties,
          ),
        ],
      ),
      body: _isLoading && _archivedProperties.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _archivedProperties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No archived properties',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Properties you\'ve marked as rented or deleted will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadArchivedProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _archivedProperties.length,
                    itemBuilder: (context, index) {
                      final property = _archivedProperties[index];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            // Archive info banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getArchiveReasonColor(property).withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    property.archiveReason == 'Property rented' 
                                      ? Icons.check_circle 
                                      : Icons.archive,
                                    size: 16,
                                    color: _getArchiveReasonColor(property),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getArchiveReasonText(property),
                                      style: TextStyle(
                                        color: _getArchiveReasonColor(property),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (property.archivedAt != null)
                                    Text(
                                      Helpers.formatDate(property.archivedAt!),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Property card
                            PropertyCard(
                              property: property,
                              showFavorite: false,
                              isInitiallyFavorite: false,
                              onTap: () {
                                // You might want to create a readonly detail screen for archived properties
                              },
                            ),
                            
                            // Action buttons
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading ? null : () => _restoreProperty(property),
                                      icon: const Icon(Icons.restore, size: 18),
                                      label: const Text('Restore'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        side: BorderSide(color: Colors.green.shade300),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (property.archiveReason == 'Property rented')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Rented',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}