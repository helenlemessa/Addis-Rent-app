import 'package:addis_rent/data/models/property_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _hasLoadedInitialData = false;
  bool _isLoading = false;
  bool _shouldLoadFavorites = true;

  @override
  void initState() {
    super.initState();
    _shouldLoadFavorites = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use a post-frame callback to avoid build conflicts
    if (_shouldLoadFavorites) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFavorites();
        }
      });
      _shouldLoadFavorites = false;
    }
  }

  Future<void> _loadFavorites() async {
    if (_hasLoadedInitialData || !mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final favoriteProvider = context.read<FavoriteProvider>();

    if (authProvider.isLoggedIn && authProvider.currentUser!.role == 'tenant') {
      final user = authProvider.currentUser!;
      print('🔄 Loading favorites for user: ${user.id}');
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Initialize provider for this user
        favoriteProvider.initializeForUser(user.id);
        
        // Load favorite properties WITH DETAILS
        await favoriteProvider.loadFavoriteProperties(user.id);
        
        _hasLoadedInitialData = true;
        print('✅ Favorites loaded successfully');
      } catch (e) {
        print('❌ Error loading favorites: $e');
        if (mounted) {
          _hasLoadedInitialData = false;
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('⚠️ User not logged in or not a tenant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
final activeFavorites = favoriteProvider.favoriteProperties
    .where((property) => !property.isArchived)
    .toList();

// Use activeFavorites instead of favoriteProvider.favoriteProperties
if (activeFavorites.isEmpty) {
  // Show empty state
}
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authProvider.currentUser!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              _debugFavorites(user.id);
            },
            tooltip: 'Debug Favorites',
          ),
          if (favoriteProvider.favoriteProperties.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await Helpers.showConfirmationDialog(
                  context,
                  title: 'Clear All Favorites',
                  content: 'Are you sure you want to remove all favorites?',
                  confirmText: 'Clear All',
                );
                if (confirmed && mounted) {
                  await favoriteProvider.clearFavorites(user.id);
                  if (mounted) {
                    Helpers.showSnackBar(
                      context,
                      'All favorites cleared',
                    );
                  }
                }
              },
              tooltip: 'Clear All Favorites',
            ),
        ],
      ),
      body: favoriteProvider.favoriteProperties.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorite properties yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Tap the heart icon on any property to add it here',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // FIX: Navigate to home screen properly
                      _navigateToHome();
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Properties'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                if (mounted) {
                  await favoriteProvider.loadFavoriteProperties(user.id);
                }
              },
              child: Column(
                children: [
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
                          '${favoriteProvider.favoriteProperties.length} ${favoriteProvider.favoriteProperties.length == 1 ? 'Property' : 'Properties'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final confirmed = await Helpers.showConfirmationDialog(
                              context,
                              title: 'Refresh Favorites',
                              content: 'Reload all favorite properties?',
                              confirmText: 'Refresh',
                            );
                            if (confirmed && mounted) {
                              await favoriteProvider.loadFavoriteProperties(user.id);
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: favoriteProvider.favoriteProperties.length,
                      itemBuilder: (context, index) {
                        final property = favoriteProvider.favoriteProperties[index];
                        return Column(
                          children: [
                            PropertyCard(
                              property: property,
                              showFavorite: true,
                              isInitiallyFavorite: true,
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
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      await favoriteProvider.removeFavorite(
                                        userId: user.id,
                                        propertyId: property.id,
                                      );
                                      if (mounted) {
                                        Helpers.showSnackBar(
                                          context,
                                          'Removed from favorites',
                                        );
                                      }
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

  // ADD THIS METHOD: Proper navigation to home
  void _navigateToHome() {
    // Method 1: Using Navigator to push home route
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false, // Remove all routes until we get to home
    );
    
    // OR Method 2: If you're using a bottom navigation bar
    // Navigator.popUntil(context, (route) {
    //   return route.settings.name == '/home' || route.isFirst;
    // });
    
    // OR Method 3: If you want to go to home tab specifically
    // Navigator.pop(context); // Go back to previous screen
    // // Then in your main/home screen, you might need to switch tabs
  }

  // ADD THIS METHOD: Refresh action button
  Widget _buildRefreshButton() {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () async {
        final user = context.read<AuthProvider>().currentUser;
        if (user != null) {
          await context.read<FavoriteProvider>().loadFavoriteProperties(user.id);
        }
      },
      tooltip: 'Refresh Favorites',
    );
  }

  Future<void> _debugFavorites(String userId) async {
    print('\n🔍 ========== DEBUG FAVORITES ==========');
    print('👤 User ID: $userId');
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 Found ${snapshot.docs.length} favorites in Firestore:');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('   • ID: ${doc.id}');
        print('     Property ID: ${data['propertyId']}');
        print('     Created: ${data['createdAt']}');
      }
      
      if (snapshot.docs.isNotEmpty) {
        final propertyIds = snapshot.docs.map((d) => d.data()['propertyId']).toList();
        print('🔄 Checking ${propertyIds.length} properties in Firestore...');
        
        // FIX: Use FieldPath.documentId instead of 'id'
        final properties = await FirebaseFirestore.instance
            .collection('properties')
            .where(FieldPath.documentId, whereIn: propertyIds)
            .get();
        
        print('📊 Found ${properties.docs.length} corresponding properties:');
        for (final doc in properties.docs) {
          final data = doc.data();
          print('   • ${data['title'] ?? 'No title'} (ID: ${doc.id})');
        }
      }
      
      final favoriteProvider = context.read<FavoriteProvider>();
      print('\n📱 Local FavoriteProvider State:');
      print('   • Favorite IDs: ${favoriteProvider.favoriteIds.toList()}');
      print('   • Favorite Properties count: ${favoriteProvider.favoriteProperties.length}');
      print('   • Is Loading: ${favoriteProvider.isLoading}');
      print('   • Error: ${favoriteProvider.error}');
      
    } catch (e) {
      print('❌ Error debugging: $e');
    }
    
    print('================================\n');
  }
}