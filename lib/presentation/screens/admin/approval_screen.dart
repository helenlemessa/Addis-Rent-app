import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/presentation/widgets/empty_state.dart';
import 'package:addis_rent/presentation/widgets/loading_shimmer.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/models/property_model.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      propertyProvider.listenToAllProperties(); // Listen to ALL properties
    });
  }

  void _loadProperties() {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.listenToAllProperties();
  }

  List<PropertyModel> _getFilteredProperties(List<PropertyModel> properties) {
    return properties.where((p) => p.status == _selectedFilter).toList();
  }

  Future<void> _showApproveDialog(PropertyModel property) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Property'),
        content: const Text(
            'Are you sure you want to approve this property listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result == true) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      try {
        await propertyProvider.updatePropertyStatus(
          propertyId: property.id,
          status: 'approved',
        );

        Helpers.showSnackBar(context, 'Property approved successfully');
        
        // Refresh the list after approval
        _loadProperties();
      } catch (e) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _showRejectDialog(PropertyModel property) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      try {
        await propertyProvider.updatePropertyStatus(
          propertyId: property.id,
          status: 'rejected',
          rejectionReason: reasonController.text.trim(),
        );

        Helpers.showSnackBar(context, 'Property rejected');
        
        // Refresh the list after rejection
        _loadProperties();
      } catch (e) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final filteredProperties =
        _getFilteredProperties(propertyProvider.properties);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProperties,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                _buildFilterTab('Pending', 'pending'),
                const SizedBox(width: 12),
                _buildFilterTab('Approved', 'approved'),
                const SizedBox(width: 12),
                _buildFilterTab('Rejected', 'rejected'),
              ],
            ),
          ),
          // Properties List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadProperties();
              },
              child: propertyProvider.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return const LoadingShimmer();
                      },
                    )
                  : filteredProperties.isEmpty
                      ? EmptyState(
                          icon: _selectedFilter == 'pending'
                              ? Icons.check_circle_outline
                              : _selectedFilter == 'approved'
                                  ? Icons.thumb_up
                                  : Icons.thumb_down,
                          title: _selectedFilter == 'pending'
                              ? 'No Pending Properties'
                              : _selectedFilter == 'approved'
                                  ? 'No Approved Properties'
                                  : 'No Rejected Properties',
                          description: _selectedFilter == 'pending'
                              ? 'All properties have been reviewed.'
                              : _selectedFilter == 'approved'
                                  ? 'No properties have been approved yet.'
                                  : 'No properties have been rejected.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProperties.length,
                          itemBuilder: (context, index) {
                            final property = filteredProperties[index];
                            return _buildPropertyCardWithActions(property);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCardWithActions(PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Property Card
          PropertyCard(
            property: property,
            showStatus: true,
            onTap: () {
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
          // Action Buttons (only for pending properties)
          if (property.status == 'pending')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View Details Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailScreen(
                            propertyId: property.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye, size: 18),
                    label: const Text('View Details'),
                  ),
                  // Approve/Reject Buttons
                  Row(
                    children: [
                      // Reject Button
                      OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(property),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Approve Button
                      ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(property),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // For approved/rejected properties, show status info
           if (property.status != 'pending')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Helpers.getStatusColor(property.status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: Helpers.getStatusColor(property.status),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    property.status == 'approved'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: Helpers.getStatusColor(property.status),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.status == 'approved'
                              ? 'Approved'
                              : 'Rejected',
                          style: TextStyle(
                            color: Helpers.getStatusColor(property.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (property.rejectionReason != null)
                          Text(
                            property.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Option to change status
                  TextButton(
                    onPressed: () {
                      if (property.status == 'approved') {
                        _showRejectDialog(property);
                      } else if (property.status == 'rejected') {
                        _showApproveDialog(property);
                      }
                    },
                    child: Text(
                      property.status == 'approved' ? 'Remove' : 'Approve',
                      style: TextStyle(
                        color: property.status == 'approved'
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _getFilterColor(value) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                _getFilterIcon(value),
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFilterColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getFilterIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}