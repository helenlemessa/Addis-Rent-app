import 'package:addis_rent/data/models/property_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/providers/favorite_provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/widgets/image_carousel.dart';
import 'package:addis_rent/presentation/widgets/amenities_chip.dart';
import 'package:addis_rent/core/utils/helpers.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    
    // First, try to find the property in memory
    PropertyModel? property;
    try {
      property = propertyProvider.properties
          .firstWhere((p) => p.id == widget.propertyId);
    } catch (e) {
      // Property not in memory, load it
      await propertyProvider.loadProperty(widget.propertyId);
    }

    // Check if favorite
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      await favoriteProvider.checkIfFavorite(
        userId: authProvider.currentUser!.id,
        propertyId: widget.propertyId,
      );
      _isFavorite = favoriteProvider.isPropertyFavorite(widget.propertyId);
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      Helpers.showSnackBar(context, 'Please login to save favorites');
      return;
    }

    await favoriteProvider.toggleFavorite(
      userId: authProvider.currentUser!.id,
      propertyId: widget.propertyId,
    );

    setState(() {
      _isFavorite = favoriteProvider.isPropertyFavorite(widget.propertyId);
    });
  }

  Future<void> _callLandlord(String phone) async {
    try {
      await Helpers.launchPhone(phone);
    } catch (e) {
      Helpers.showSnackBar(context, 'Could not make call: $e', isError: true);
    }
  }

 Future<void> _emailLandlord(String email) async {
  try {
    await Helpers.launchEmail(email);
  } catch (e) {
    // If email launch fails, copy to clipboard
    await Clipboard.setData(ClipboardData(text: email));
    
    // Show a better error message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email App Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No email app found on your device.'),
            const SizedBox(height: 8),
            Text('Email address: $email'),
            const SizedBox(height: 16),
            const Text('The email address has been copied to your clipboard.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    
    // Try to get property from memory first
    PropertyModel? property;
    try {
      property = propertyProvider.properties
          .firstWhere((p) => p.id == widget.propertyId);
    } catch (e) {
      // If not in memory, use selectedProperty
      property = propertyProvider.selectedProperty;
    }

    // Show loading if property is null or has no title
    if (propertyProvider.isLoading || property == null || property.title.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ImageCarousel(
                images: property.images,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      Text(
                        property.formattedPrice,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location and Type
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.apartment, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        property.propertyType,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bedrooms and Bathrooms
                  Row(
                    children: [
                      _buildFeatureItem(
                        icon: Icons.bed,
                        text:
                            '${property.bedrooms} Bedroom${property.bedrooms > 1 ? 's' : ''}',
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureItem(
                        icon: Icons.bathtub,
                        text:
                            '${property.bathrooms} Bathroom${property.bathrooms > 1 ? 's' : ''}',
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureItem(
                        icon: Icons.check_circle,
                        text: property.status == 'approved'
                            ? 'Verified'
                            : 'Pending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // Amenities
                  Text(
                    'Amenities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.amenities
                        .map((amenity) => AmenitiesChip(amenity: amenity))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // Landlord Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Landlord',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            property.landlordName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(property.landlordPhone),
                              Text(property.landlordEmail),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _callLandlord(property!.landlordPhone),
                                icon: const Icon(Icons.call),
                                label: const Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _emailLandlord(property!.landlordEmail),
                                icon: const Icon(Icons.email),
                                label: const Text('Email'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Property Status (for landlords)
                  if (property.landlordId ==
                      Provider.of<AuthProvider>(context).currentUser?.id)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Helpers.getStatusColor(property.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Helpers.getStatusColor(property.status),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            property.status == 'approved'
                                ? Icons.check_circle
                                : property.status == 'pending'
                                    ? Icons.access_time
                                    : Icons.cancel,
                            color: Helpers.getStatusColor(property.status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${Helpers.getStatusText(property.status)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Helpers.getStatusColor(property.status),
                                  ),
                                ),
                                if (property.rejectionReason != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Reason: ${property.rejectionReason!}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}