import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/presentation/providers/favorite_provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showFavorite;
  final Widget? actionButtons;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.showStatus = false,
    this.showFavorite = true,
    this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize favorite provider for current user when card is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final favoriteProvider = context.read<FavoriteProvider>();
      
      if (authProvider.isLoggedIn && showFavorite) {
        final user = authProvider.currentUser!;
        favoriteProvider.initializeForUser(user.id);
        // Check if this property is favorite
        favoriteProvider.checkIfFavorite(
          userId: user.id,
          propertyId: property.id,
        );
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: property.images.isNotEmpty
                      ? SizedBox(
                          width: double.infinity,
                          height: 180,
                          child: Helpers.buildPropertyImage(
                            property.images.first,
                            width: double.infinity,
                            height: 180,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.home,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Status Badge
                if (showStatus && property.status != 'approved')
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Helpers.getStatusColor(property.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        property.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Favorite Button
                if (showFavorite)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        if (!authProvider.isLoggedIn) {
                          return GestureDetector(
                            onTap: () {
                              Helpers.showSnackBar(
                                context,
                                'Please login to save favorites',
                                isError: true,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_border,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        
                        return Consumer<FavoriteProvider>(
                          builder: (context, favoriteProvider, child) {
                            final isFavorite = favoriteProvider.isPropertyFavorite(property.id);
                            
                            return GestureDetector(
                              onTap: () async {
                                final user = authProvider.currentUser!;
                                
                                try {
                                  print('❤️ Toggling favorite for property: ${property.id}');
                                  await favoriteProvider.toggleFavorite(
                                    userId: user.id,
                                    propertyId: property.id,
                                  );
                                  print('✅ Favorite toggled. Is now favorite: $isFavorite');
                                  
                                  // Show feedback
                                  Helpers.showSnackBar(
                                    context,
                                    isFavorite ? 'Added to favorites' : 'Removed from favorites',
                                  );
                                } catch (e) {
                                  print('❌ Error toggling favorite: $e');
                                  Helpers.showSnackBar(
                                    context,
                                    'Failed to update favorite',
                                    isError: true,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                // Price Tag
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Location and Type
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.apartment,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        property.propertyType,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Features
                  Row(
                    children: [
                      _buildFeatureItem(
                        icon: Icons.bed,
                        text: '${property.bedrooms} bed',
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureItem(
                        icon: Icons.bathtub,
                        text: '${property.bathrooms} bath',
                      ),
                      const Spacer(),
                      // Amenities Count
                      if (property.amenities.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${property.amenities.length} amenities',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Action Buttons (for admin approval screen, etc.)
                  if (actionButtons != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [actionButtons!],
                      ),
                    ),
                  // Status Info
                  if (showStatus && property.status != 'approved')
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Helpers.getStatusColor(property.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Helpers.getStatusColor(property.status)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            property.status == 'pending'
                                ? Icons.access_time
                                : Icons.info,
                            size: 16,
                            color: Helpers.getStatusColor(property.status),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              property.status == 'pending'
                                  ? 'Under review - will be visible after approval'
                                  : property.rejectionReason ??
                                      'Property was rejected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Helpers.getStatusColor(property.status),
                              ),
                              maxLines: 2,
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
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}