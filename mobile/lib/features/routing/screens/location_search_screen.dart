import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/location_search_service.dart';
import '../../map/providers/map_provider.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  final String fieldType; // 'origin', 'destination', or 'waypoint'

  const LocationSearchScreen({super.key, required this.fieldType});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    final searchService = ref.read(locationSearchServiceProvider);
    final mapState = ref.read(mapProvider);

    final results = await searchService.search(
      query,
      nearLocation: mapState.currentLocation,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  void _selectResult(SearchResult result) {
    // Return result to previous screen
    context.pop(result);
  }

  void _useCurrentLocation() async {
    final mapState = ref.read(mapProvider);
    if (mapState.currentLocation != null) {
      final searchService = ref.read(locationSearchServiceProvider);
      final result = await searchService.reverseGeocode(mapState.currentLocation!);
      if (result != null && mounted) {
        context.pop(result);
      } else if (mounted) {
        // Create a simple result from current location
        context.pop(SearchResult(
          displayName: 'Current Location',
          name: 'Current Location',
          location: mapState.currentLocation!,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search address, city, or place...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),

          // Current location option (for origin)
          if (widget.fieldType == 'origin' && mapState.currentLocation != null)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.my_location, color: Colors.white),
              ),
              title: const Text('Use current location'),
              subtitle: const Text('Your GPS position'),
              onTap: _useCurrentLocation,
            ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          // Results list
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(
                            _getIconForType(result.type),
                            color: Colors.grey[700],
                          ),
                        ),
                        title: Text(
                          result.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _selectResult(result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.fieldType) {
      case 'origin':
        return 'Starting point';
      case 'destination':
        return 'Destination';
      default:
        return 'Add waypoint';
    }
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for a location',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an address, city, or place name',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'road':
      case 'street':
        return Icons.route;
      case 'warehouse':
      case 'industrial':
        return Icons.warehouse;
      default:
        return Icons.place;
    }
  }
}
