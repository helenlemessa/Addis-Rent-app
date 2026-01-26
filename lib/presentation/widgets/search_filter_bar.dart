import 'dart:async';

import 'package:flutter/material.dart';

class SearchFilterBar extends StatefulWidget {
  final void Function(String)? onSearchChanged;
  final void Function()? onFilterPressed;
  final String? initialValue;

  const SearchFilterBar({
    super.key,
    this.onSearchChanged,
    this.onFilterPressed,
    this.initialValue,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _searchController = TextEditingController();
  final _debounceTimer = Duration(milliseconds: 300);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.initialValue != null) {
      _searchController.text = widget.initialValue!;
    }
  }

  void _onSearchChanged() {
    final text = _searchController.text;
  print('🔍 SearchFilterBar: Text changed to: "$text"');
  
  // Call immediately, no debounce
  widget.onSearchChanged?.call(text);
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(_debounceTimer, () {
      final text = _searchController.text;
      print('🔍 SearchFilterBar: Text changed to: "$text"');
      widget.onSearchChanged?.call(text);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged?.call('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                  controller: _searchController,
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    // Trigger search immediately on typing
                    widget.onSearchChanged?.call(value);
                  },),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: widget.onFilterPressed,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              tooltip: 'Filter properties',
            ),
          ),
        ],
      ),
    );
  }
}
