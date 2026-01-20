// Create new file: lib/presentation/screens/admin/property_cleanup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/repositories/property_archive_repository.dart';

class PropertyCleanupScreen extends StatefulWidget {
  const PropertyCleanupScreen({super.key});

  @override
  State<PropertyCleanupScreen> createState() => _PropertyCleanupScreenState();
}

class _PropertyCleanupScreenState extends State<PropertyCleanupScreen> {
  final PropertyArchiveRepository _repository = PropertyArchiveRepository();
  List<PropertyModel> _oldProperties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOldProperties();
  }

  Future<void> _loadOldProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final properties = await _repository.getOldProperties();
      if (mounted) {
        setState(() {
          _oldProperties = properties;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading old properties: $e',
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

  Future<void> _deleteProperty(PropertyModel property) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Archive Old Property',
      content: 'Archive "${property.title}"? This property is older than 3 months.',
      confirmText: 'Archive',
    );

    if (!confirmed) return;

    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser!.id;

    try {
      await _repository.adminDeleteOldProperty(
        propertyId: property.id,
        adminId: adminId,
      );

      if (mounted) {
        setState(() {
          _oldProperties.removeWhere((p) => p.id == property.id);
        });
      }

      Helpers.showSnackBar(
        context,
        'Property archived successfully',
      );
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error archiving property: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Old Properties Cleanup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOldProperties,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _oldProperties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'No old properties found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All properties are up to date',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_oldProperties.length} Properties Older Than 3 Months',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'These properties should be reviewed and archived',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Properties List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _oldProperties.length,
                        itemBuilder: (context, index) {
                          final property = _oldProperties[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                PropertyCard(
                                  property: property,
                                  showFavorite: false,
                                  showStatus: true,
                                  onTap: () {
                                    // Show property details
                                  },
                                ),
                                // Admin actions
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Property age info
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Posted ${Helpers.formatDate(property.createdAt)}',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Delete button
                                      ElevatedButton(
                                        onPressed: () => _deleteProperty(property),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Archive'),
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
                  ],
                ),
    );
  }
}