import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/data/models/property_model.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/presentation/providers/favorite_provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';

class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showFavorite;
  final Widget? actionButtons;
  final bool isInitiallyFavorite;
  final bool showLandlordActions;
  final VoidCallback? onMarkAsRented;
  final VoidCallback? onDeleteProperty;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.showStatus = false,
    this.showFavorite = true,
    this.actionButtons,
    this.isInitiallyFavorite = false,
    this.showLandlordActions = false,
    this.onMarkAsRented,
    this.onDeleteProperty,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
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
                  child: widget.property.images.isNotEmpty
                      ? SizedBox(
                          width: double.infinity,
                          height: 180,
                          child: Helpers.buildPropertyImage(
                            widget.property.images.first,
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
                if (widget.showStatus && widget.property.status != 'approved')
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Helpers.getStatusColor(widget.property.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.property.status.toUpperCase(),
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
                if (widget.showFavorite)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        if (!authProvider.isLoggedIn) {
                          return GestureDetector(
                            onTap: () {
                              if (mounted) {
                                Helpers.showSnackBar(
                                  context,
                                  'Please login to save favorites',
                                  isError: true,
                                );
                              }
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
                            final isFavorite = favoriteProvider.isPropertyFavorite(widget.property.id);
                            
                            return GestureDetector(
                              onTap: () async {
                                final user = authProvider.currentUser!;
                                
                                try {
                                  print('❤️ Toggling favorite for property: ${widget.property.id}');
                                  
                                  // Check if widget is still mounted
                                  if (!mounted) return;
                                  
                                  await favoriteProvider.toggleFavorite(
                                    userId: user.id,
                                    propertyId: widget.property.id,
                                  );
                                  
                                  print('✅ Favorite toggled. Is now favorite: ${favoriteProvider.isPropertyFavorite(widget.property.id)}');
                                  
                                  // Show feedback only if still mounted
                                  if (mounted) {
                                    final currentIsFavorite = favoriteProvider.isPropertyFavorite(widget.property.id);
                                    Helpers.showSnackBar(
                                      context,
                                      currentIsFavorite ? 'Added to favorites' : 'Removed from favorites',
                                    );
                                  }
                                } catch (e) {
                                  print('❌ Error toggling favorite: $e');
                                  if (mounted) {
                                    Helpers.showSnackBar(
                                      context,
                                      'Failed to update favorite',
                                      isError: true,
                                    );
                                  }
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
                // Landlord Actions Button
                if (widget.showLandlordActions)
                  Positioned(
                    bottom: 12,
                    right: 12,
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
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'rented' && widget.onMarkAsRented != null) {
                            widget.onMarkAsRented!();
                          } else if (value == 'delete' && widget.onDeleteProperty != null) {
                            widget.onDeleteProperty!();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rented',
                            child: Row(
                              children: [
                                Icon(Icons.done_all, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Mark as Rented'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Property'),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      widget.property.formattedPrice,
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
                    widget.property.title,
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
                          widget.property.location,
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
                        widget.property.propertyType,
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
                        text: '${widget.property.bedrooms} bed',
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureItem(
                        icon: Icons.bathtub,
                        text: '${widget.property.bathrooms} bath',
                      ),
                      const Spacer(),
                      // Amenities Count
                      if (widget.property.amenities.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.property.amenities.length} amenities',
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
                  // Action Buttons
                  if (widget.actionButtons != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [widget.actionButtons!],
                      ),
                    ),
                  // Status Info
                  if (widget.showStatus && widget.property.status != 'approved')
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Helpers.getStatusColor(widget.property.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Helpers.getStatusColor(widget.property.status)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.property.status == 'pending'
                                ? Icons.access_time
                                : Icons.info,
                            size: 16,
                            color: Helpers.getStatusColor(widget.property.status),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.property.status == 'pending'
                                  ? 'Under review - will be visible after approval'
                                  : widget.property.rejectionReason ??
                                      'Property was rejected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Helpers.getStatusColor(widget.property.status),
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