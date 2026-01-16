// lib/presentation/screens/property/add_property_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/providers/auth_provider.dart';
import 'package:addis_rent/presentation/widgets/custom_text_field.dart';
import 'package:addis_rent/presentation/widgets/primary_button.dart';
import 'package:addis_rent/core/utils/validators.dart';
import 'package:addis_rent/core/constants/app_constants.dart';
import 'package:addis_rent/data/models/property_model.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');

  String? _selectedPropertyType;
  String? _selectedLocation;
  final List<String> _selectedAmenities = [];
  final List<String> _selectedImages = [];

  Future<void> _pickImages() async {
    try {
      if (kIsWeb) {
        await _pickImagesWeb();
      } else {
        await _pickImagesMobile();
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImagesMobile() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => file.path).toList());
      });
      print('📸 Added ${pickedFiles.length} images. Total: ${_selectedImages.length}');
    }
  }

  Future<void> _pickImagesWeb() async {
    final input = html.FileUploadInputElement();
    input.multiple = true;
    input.accept = 'image/*';
    
    input.click();
    
    await input.onChange.first;
    
    if (input.files != null && input.files!.isNotEmpty) {
      final files = input.files!;
      final imageSources = <String>[];
      
      for (final file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        
        await reader.onLoad.first;
        
        if (reader.result != null) {
          imageSources.add(reader.result as String);
        }
      }
      
      if (imageSources.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(imageSources);
        });
        print('📸 Added ${imageSources.length} images from web. Total: ${_selectedImages.length}');
        
        // Show first image preview in console
        if (imageSources.isNotEmpty) {
          final firstImage = imageSources.first;
          print('🖼️ First image type: ${firstImage.substring(0, 50)}...');
        }
      }
    }
  }

  Future<void> _submitProperty() async {
    print('\n🚀 ========== STARTING PROPERTY SUBMISSION ==========');
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('✅ Form validation passed');
    
    // Check for required fields
    if (_selectedPropertyType == null) {
      print('❌ Property type not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a property type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedLocation == null) {
      print('❌ Location not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check for images
    if (_selectedImages.isEmpty) {
      print('❌ No images selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('✅ All required fields checked');
    
    // Get providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      print('❌ No user found! User is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add properties'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('👤 User found:');
    print('   - ID: ${user.id}');
    print('   - Email: ${user.email}');
    print('   - Role: ${user.role}');
    
    try {
      print('\n📝 CREATING PROPERTY MODEL...');
      
      // Create property model
      final property = PropertyModel(
        id: '', // Will be generated by Firebase
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _selectedPropertyType!,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        location: _selectedLocation!,
        bedrooms: int.tryParse(_bedroomsController.text.trim()) ?? 1,
        bathrooms: int.tryParse(_bathroomsController.text.trim()) ?? 1,
        amenities: _selectedAmenities,
        images: _selectedImages, // These will be uploaded to Firebase
        landlordId: user.id,
        landlordName: user.fullName,
        landlordPhone: user.phone,
        landlordEmail: user.email,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      
      print('\n🔗 CALLING PROPERTY PROVIDER...');
      
      // Submit to Firebase (will upload images)
      await propertyProvider.createProperty(property);
      
      print('\n🎉 PROPERTY SUBMITTED SUCCESSFULLY!');
      print('==========================================\n');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property submitted for review!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.pop(context);
      
    } catch (e) {
      print('\n❌ ERROR SUBMITTING PROPERTY:');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      
      // Show error message
      String errorMessage = 'Error submitting property: ${e.toString()}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('==========================================\n');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    print('🗑️ Removed image at index $index. Remaining: ${_selectedImages.length}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Images
              _buildSectionTitle('Property Images'),
              const SizedBox(height: 8),
              Text(
                'Add at least one clear image of your property',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              // Image Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _buildAddImageButton();
                  }
                  return _buildImageThumbnail(index);
                },
              ),
              const SizedBox(height: 24),
              
              // Property Details
              _buildSectionTitle('Property Details'),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _titleController,
                labelText: 'Property Title*',
                hintText: 'e.g., Beautiful 2 Bedroom Apartment in Bole',
                validator: Validators.validateTitle,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description*',
                hintText: 'Describe your property in detail...',
                maxLines: 5,
                validator: Validators.validateDescription,
              ),
              const SizedBox(height: 16),
              
              // Property Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedPropertyType,
                decoration: InputDecoration(
                  labelText: 'Property Type*',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: AppConstants.propertyTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyType = value;
                  });
                  print('🏠 Selected property type: $value');
                },
                validator: (value) =>
                    Validators.validateRequired(value, 'Property type'),
              ),
              const SizedBox(height: 16),
              
              // Location Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  labelText: 'Location*',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: AppConstants.locations
                    .map((location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                  print('📍 Selected location: $value');
                },
                validator: (value) =>
                    Validators.validateRequired(value, 'Location'),
              ),
              const SizedBox(height: 16),
              
              // Price and Room Details
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      labelText: 'Monthly Price (ETB)*',
                      keyboardType: TextInputType.number,
                      validator: Validators.validatePrice,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _bedroomsController,
                      labelText: 'Bedrooms*',
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.validatePositiveInteger(
                        value,
                        'Bedrooms',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _bathroomsController,
                      labelText: 'Bathrooms*',
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.validatePositiveInteger(
                        value,
                        'Bathrooms',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Amenities
              _buildSectionTitle('Amenities'),
              const SizedBox(height: 8),
              Text(
                'Select all that apply',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.amenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    checkmarkColor: Colors.white,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              PrimaryButton(
                onPressed: propertyProvider.isLoading ? null : _submitProperty,
                isLoading: propertyProvider.isLoading,
                child: const Text('Submit Property for Review'),
              ),
              const SizedBox(height: 16),
              
              // Note
              _buildInfoNote(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
              SizedBox(height: 4),
              Text('Add Image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    final imageSource = _selectedImages[index];
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: _getImageProvider(imageSource),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _getImageProvider(String imageSource) {
    if (imageSource.startsWith('data:image') || 
        imageSource.startsWith('blob:')) {
      // For web data URLs or blob URLs
      return NetworkImage(imageSource);
    } else if (imageSource.startsWith('http')) {
      // For network URLs
      return NetworkImage(imageSource);
    } else {
      // For local file paths (mobile only)
      if (kIsWeb) {
        // Fallback for web
        return const AssetImage('assets/images/placeholder.png');
      } else {
        return FileImage(File(imageSource));
      }
    }
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your property will be reviewed by our admin team before appearing in search results. This usually takes 24-48 hours.',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}