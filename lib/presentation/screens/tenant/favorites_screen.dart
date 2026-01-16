import 'package:addis_rent/data/models/property_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/favorite_provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/core/utils/helpers.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      final user = authProvider.currentUser!;
      // Initialize favorite provider for this user
      favoriteProvider.initializeForUser(user.id);
      // Load favorites
      favoriteProvider.loadFavorites(user.id);
      
      // Also load properties to get detailed info
      propertyProvider.loadProperties(status: 'approved');
    }
  }

  List<PropertyModel> _getFavoriteProperties() {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    // Get properties that are in favorites
    final favoriteProperties = propertyProvider.properties
        .where((property) => favoriteProvider.isPropertyFavorite(property.id))
        .toList();

    // Update the favorite provider with actual property objects
    if (favoriteProperties.isNotEmpty) {
      favoriteProvider.setFavoriteProperties(favoriteProperties);
    }

    return favoriteProperties;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);

    if (!authProvider.isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please login to view favorites',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Initialize for user when screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.isLoggedIn) {
        final user = authProvider.currentUser!;
        favoriteProvider.initializeForUser(user.id);
      }
    });

    final favoriteProperties = _getFavoriteProperties();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        actions: [
          if (favoriteProperties.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await Helpers.showConfirmationDialog(
                  context,
                  title: 'Clear All Favorites',
                  content: 'Are you sure you want to remove all favorites?',
                  confirmText: 'Clear All',
                );
                if (confirmed) {
                  final user = authProvider.currentUser!;
                  await favoriteProvider.clearFavorites(user.id);
                  Helpers.showSnackBar(
                    context,
                    'All favorites cleared',
                  );
                }
              },
              tooltip: 'Clear All Favorites',
            ),
        ],
      ),
      body: favoriteProvider.isLoading || propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteProperties.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No favorite properties yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Tap the heart icon on any property to add it here',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadFavorites();
                  },
                  child: Column(
                    children: [
                      // Header with count
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${favoriteProperties.length} ${favoriteProperties.length == 1 ? 'Property' : 'Properties'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Properties list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: favoriteProperties.length,
                          itemBuilder: (context, index) {
                            final property = favoriteProperties[index];
                            return Column(
                              children: [
                                PropertyCard(
                                  property: property,
                                  showFavorite: true,
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
                                // Add a remove button below each favorite
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          final user = authProvider.currentUser!;
                                          await favoriteProvider.removeFavorite(
                                            userId: user.id,
                                            propertyId: property.id,
                                          );
                                          Helpers.showSnackBar(
                                            context,
                                            'Removed from favorites',
                                          );
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        label: const Text('Remove'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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