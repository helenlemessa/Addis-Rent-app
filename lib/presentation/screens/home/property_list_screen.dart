// lib/presentation/screens/home/property_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';
import 'package:addis_rent/presentation/widgets/search_filter_bar.dart';
import 'package:addis_rent/core/utils/helpers.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String? _selectedLocation;
  String? _selectedType;
  int? _selectedBedrooms;
  double _minPrice = 0;
  double _maxPrice = 100000;
  // In PropertyProvider class
 
  // Add this variable to track if we should restore search
  bool _shouldRestoreSearch = true;

  @override
  void initState() {
    super.initState();
    print('🔄 PropertyListScreen initState() called');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
      
      // Restore search from provider if it exists
      _restoreSearchState();
    });
  }
  
 void _restoreSearchState() {
  final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
  
  if (propertyProvider.searchQuery.isNotEmpty) {  // Use the public getter
    print('🔍 Restoring search query: "${propertyProvider.searchQuery}"');
    _searchController.text = propertyProvider.searchQuery;
    
    // Trigger search with restored query
    _performSearch(propertyProvider.searchQuery);
  } else {
    print('ℹ️ No search query to restore');
    // Clear filters to show all properties
    propertyProvider.clearFilters();
  }
}

  @override
  void dispose() {
    print('🗑️ PropertyListScreen disposing');
    // Don't clear provider filters when disposing
    super.dispose();
  }
  void _loadProperties() {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.listenToApprovedProperties();
  }
void _performSearch(String searchText) {
  final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
  
  print('🔍 Performing search with: "$searchText"');
  
  // Only apply price filters if they're different from defaults
  final double? minPriceToApply = (_minPrice > 0) ? _minPrice : null;
  final double? maxPriceToApply = (_maxPrice < 100000) ? _maxPrice : null;
  
  propertyProvider.applyFilters(
    query: searchText.trim(),  // Use the parameter
    location: _selectedLocation,
    propertyType: _selectedType,
    minPrice: minPriceToApply,
    maxPrice: maxPriceToApply,
    bedrooms: _selectedBedrooms,
  );
}
  void _clearFilters() {
    _searchController.clear();
    _selectedLocation = null;
    _selectedType = null;
    _selectedBedrooms = null;
    _minPrice = 0;
    _maxPrice = 100000;
    _showFilters = false;
    
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final uniqueLocations = propertyProvider.uniqueLocations;
    final uniquePropertyTypes = propertyProvider.uniquePropertyTypes;
    final availableBedrooms = propertyProvider.availableBedrooms;

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          SearchFilterBar(
            onSearchChanged: (value) {
              _performSearch(value);
            },
            onFilterPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            initialValue: _searchController.text,
          ),
          
          // Filter Section
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  // Location Filter
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ...uniqueLocations.map(
                        (location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                      _performSearch(value ?? '');
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Property Type Filter
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Property Type',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...uniquePropertyTypes.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                      _performSearch(value ?? '');
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Bedrooms Filter
                  DropdownButtonFormField<int>(
                    value: _selectedBedrooms,
                    decoration: const InputDecoration(
                      labelText: 'Bedrooms',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...availableBedrooms.map(
                        (bedrooms) => DropdownMenuItem(
                          value: bedrooms,
                          child: Text('$bedrooms Bedroom${bedrooms > 1 ? 's' : ''}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBedrooms = value;
                      });
                      _performSearch(value != null ? value.toString() : '');
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Price Range
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Price Range (ETB)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Min',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: 'ETB',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _minPrice = double.tryParse(value) ?? 0;
                                _performSearch(value ?? '');
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Max',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: 'ETB',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _maxPrice = double.tryParse(value) ?? 100000;
                                _performSearch(value ?? '');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Clear Filters Button
                  ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear All Filters'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          
          // Filter Summary & Results
          Expanded(
            child: propertyProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Filter Summary
                      if (_searchController.text.isNotEmpty ||
                          _selectedLocation != null ||
                          _selectedType != null ||
                          _selectedBedrooms != null ||
                          _minPrice > 0 ||
                          _maxPrice < 100000)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Colors.grey.shade50,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  propertyProvider.filterSummary,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: _clearFilters,
                                tooltip: 'Clear filters',
                              ),
                            ],
                          ),
                        ),
                      
                      // Properties List
                      Expanded(
                        child: propertyProvider.filteredProperties.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No properties found',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 32.0),
                                      child: Text(
                                        'Try adjusting your search or filters',
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  _loadProperties();
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      propertyProvider.filteredProperties.length,
                                  itemBuilder: (context, index) {
                                    final property =
                                        propertyProvider.filteredProperties[index];
                                    return PropertyCard(
                                      property: property,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PropertyDetailScreen(
                                              propertyId: property.id,
                                            ),
                                          ),
                                        );
                                      },
                                       isInitiallyFavorite: false,
                                    );
                                  },
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

   
}
 