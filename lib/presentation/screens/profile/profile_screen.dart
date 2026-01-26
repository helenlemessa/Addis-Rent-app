import 'package:addis_rent/presentation/providers/favorite_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/providers/user_provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart'; // ADD THIS
import 'dart:io';
import 'package:addis_rent/presentation/widgets/primary_button.dart';
import 'package:addis_rent/presentation/widgets/custom_text_field.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/core/utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImage;
  int _propertyCount = 0; // ADD THIS

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadPropertyCount(); // ADD THIS
    });
  }

  void _loadUserData() {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
  final user = authProvider.currentUser;

  if (user != null) {
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phone;
    _emailController.text = user.email;
    _profileImage = user.profileImage;
    
    // Load favorites if user is tenant
    if (user.role == 'tenant') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        favoriteProvider.loadFavoriteProperties(user.id);
      });
    }
  }
}

  // ADD THIS METHOD: Load property count for landlords
  void _loadPropertyCount() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && user.role == 'landlord') {
      // Count properties owned by this landlord
      final myProperties = propertyProvider.myProperties;
      final count = myProperties.length;
      
      setState(() {
        _propertyCount = count;
      });
      
      print('👤 User: ${user.fullName} (${user.role})');
      print('🏠 Property count: $count');
      print('📋 Properties: ${myProperties.map((p) => p.title).toList()}');
    }
  }

  // ADD THIS: Listen to property changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen to property provider changes
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    if (user != null && user.role == 'landlord') {
      // Update count when properties change
      final count = propertyProvider.myProperties.length;
      if (count != _propertyCount) {
        setState(() {
          _propertyCount = count;
        });
        print('🔄 Updated property count: $count');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = authProvider.currentUser!;

    try {
      final imageUrl = _profileImage;

      await userProvider.updateUserProfile(
        userId: user.id,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImage: imageUrl,
      );

      await authProvider.initialize();

      setState(() {
        _isEditing = false;
      });

      Helpers.showSnackBar(context, 'Profile updated successfully');
    } catch (e) {
      Helpers.showSnackBar(context, 'Error updating profile: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Show a loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Perform logout
        await authProvider.logout();
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );

        // Show success message
        if (mounted) {
          Helpers.showSnackBar(context, 'Logged out successfully');
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Helpers.showSnackBar(context, 'Error logging out: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
Future<void> _refreshFavorites() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
  final user = authProvider.currentUser;
  
  if (user != null && user.role == 'tenant') {
    await favoriteProvider.loadFavoriteProperties(user.id);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Favorites refreshed'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
  Future<void> _deleteAccount() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Delete Account',
      content:
          'This action cannot be undone. All your data will be permanently deleted.',
      confirmText: 'Delete Account',
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = authProvider.currentUser!;

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await userProvider.deleteUser(user.id);
        await authProvider.logout();

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }

        if (mounted) {
          Helpers.showSnackBar(context, 'Account deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Helpers.showSnackBar(context, 'Error deleting account: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildUserInfoSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser!;

    return Column(
      children: [
        // Profile Image
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: _profileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.file(
                        File(_profileImage!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        Helpers.getInitials(user.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // User Name and Role
        Text(
          user.fullName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.role.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (user.isVerified)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'landlord':
        return Colors.blue;
      case 'tenant':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

 Widget _buildStatsSection() {
  final authProvider = Provider.of<AuthProvider>(context);
  final user = authProvider.currentUser!;
  
  // Get favorite provider to access actual favorites count
  final favoriteProvider = Provider.of<FavoriteProvider>(context);
  
  // Get property provider
  final propertyProvider = Provider.of<PropertyProvider>(context);
  
  // ACTUAL favorite count from FavoriteProvider
  final favoriteCount = favoriteProvider.favoriteProperties.length;
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.calendar_today,
          label: 'Member Since',
          value: Helpers.formatDate(user.createdAt),
        ),
        
        // Show property count for landlords
        if (user.role == 'landlord')
          _buildStatItem(
            icon: Icons.apartment,
            label: 'Properties',
            value: '$_propertyCount',
          ),
        
        // Show ACTUAL favorites count for tenants
        if (user.role == 'tenant')
          _buildStatItem(
            icon: Icons.favorite,
            label: 'Favorites',
            value: '$favoriteCount',
          ),
        
        // Show pending properties count for landlords
        if (user.role == 'landlord')
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Pending',
            value: '${propertyProvider.myProperties.where((p) => p.status == 'pending').length}',
          ),
      ],
    ),
  );
}

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _fullNameController,
            labelText: 'Full Name',
            enabled: _isEditing,
            validator: Validators.validateName,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            enabled: false,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            labelText: 'Phone Number',
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPropertyListSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final user = authProvider.currentUser!;
    
    if (user.role != 'landlord' || propertyProvider.myProperties.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'My Properties ($_propertyCount)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...propertyProvider.myProperties.take(3).map((property) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: property.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Helpers.buildPropertyImage(
                            property.images.first,
                            width: 60,
                            height: 60,
                          ),
                        )
                      : const Icon(Icons.home, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Helpers.getStatusColor(property.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          property.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Helpers.formatCurrency(property.price),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        if (propertyProvider.myProperties.length > 3)
          TextButton(
            onPressed: () {
              // Navigate to My Properties screen
              Navigator.pushNamed(context, '/my-properties');
            },
            child: const Text('View All Properties →'),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButtons() {
    final authProvider = Provider.of<AuthProvider>(context);
  final user = authProvider.currentUser!;
  
  return Column(
    children: [
      if (!_isEditing)
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                child: const Text('Edit Profile'),
              ),
            ),
            // Add refresh button for tenant favorites
            if (user.role == 'tenant')
              IconButton(
                onPressed: _isLoading ? null : _refreshFavorites,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Favorites',
              ),
          ],
        ),
        if (_isEditing)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                _loadUserData();
                              });
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      isLoading: _isLoading,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the camera icon on your profile picture to change it',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        const SizedBox(height: 24),
        
        // Show property list for landlords
        _buildPropertyListSection(),
        
        // Account Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Logout'),
                trailing: _isLoading ? const CircularProgressIndicator() : null,
                onTap: _isLoading ? null : _logout,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account'),
                trailing: _isLoading ? const CircularProgressIndicator() : null,
                onTap: _isLoading ? null : _deleteAccount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateProfile,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserInfoSection(),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildProfileForm(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}