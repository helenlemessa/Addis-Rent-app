import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/property_provider.dart';
import 'package:addis_rent/presentation/screens/home/property_detail_screen.dart';
import 'package:addis_rent/presentation/widgets/property_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
      // Auto-focus search field when entering search screen
      _searchFocusNode.requestFocus();
    });
  }

  void _loadProperties() {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.listenToApprovedProperties();
  }

  void _performSearch() {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.search(_searchController.text.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search properties...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                      color: Colors.grey,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => _performSearch(),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => _performSearch(),
          ),
        ),
      ),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Results Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Showing all approved properties'
                              : 'Search results for "${_searchController.text}"',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${propertyProvider.filteredProperties.length} found',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Properties List
                Expanded(
                  child: propertyProvider.filteredProperties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isEmpty
                                    ? Icons.home
                                    : Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No properties available'
                                    : 'No properties found for "${_searchController.text}"',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (_searchController.text.isNotEmpty)
                                TextButton(
                                  onPressed: _clearSearch,
                                  child: const Text('Clear search'),
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
                                      builder: (context) => PropertyDetailScreen(
                                        propertyId: property.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}