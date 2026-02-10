import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_search_service.dart';
import '../../map/providers/map_provider.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  final String fieldType;

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

  // Mock recent places - would come from local storage
  final List<_RecentPlace> _recentPlaces = [
    _RecentPlace(
      name: 'Munich, Germany',
      address: 'Bavaria, Germany',
      icon: Icons.location_city,
      location: const LatLng(48.1351, 11.5820),
    ),
    _RecentPlace(
      name: 'Rotterdam Port',
      address: 'Europoort, Netherlands',
      icon: Icons.directions_boat,
      location: const LatLng(51.9225, 4.4792),
    ),
    _RecentPlace(
      name: 'Warsaw Distribution Hub',
      address: 'Pruszków, Poland',
      icon: Icons.warehouse,
      location: const LatLng(52.1707, 20.8116),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

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
    context.pop(result);
  }

  void _selectRecentPlace(_RecentPlace place) {
    context.pop(SearchResult(
      displayName: place.address,
      name: place.name,
      location: place.location,
    ));
  }

  void _useCurrentLocation() async {
    final mapState = ref.read(mapProvider);
    if (mapState.currentLocation != null) {
      setState(() => _isLoading = true);
      final searchService = ref.read(locationSearchServiceProvider);
      final result = await searchService.reverseGeocode(mapState.currentLocation!);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result != null) {
          context.pop(result);
        } else {
          context.pop(SearchResult(
            displayName: 'Current Location',
            name: 'Current Location',
            location: mapState.currentLocation!,
          ));
        }
      }
    }
  }

  double? _calculateDistance(LatLng location) {
    final mapState = ref.read(mapProvider);
    if (mapState.currentLocation == null) return null;
    const distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      mapState.currentLocation!,
      location,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final hasQuery = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Search header - Uber/Google Maps style
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Where to?',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              suffixIcon: hasQuery
                                  ? IconButton(
                                      icon: Icon(Icons.close, color: Colors.grey[600]),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _results = []);
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: hasQuery ? _buildSearchResults() : _buildSuggestions(mapState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(MapState mapState) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Current location
        if (mapState.currentLocation != null)
          _buildOptionTile(
            icon: Icons.my_location,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue[50]!,
            title: 'Current location',
            subtitle: 'Use GPS',
            onTap: _useCurrentLocation,
          ),

        // Set location on map
        _buildOptionTile(
          icon: Icons.map,
          iconColor: Colors.green,
          iconBgColor: Colors.green[50]!,
          title: 'Choose on map',
          subtitle: 'Select a point',
          onTap: () {
            // TODO: Open map picker
          },
        ),

        const SizedBox(height: 16),

        // Recent places header
        if (_recentPlaces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recent',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Recent places
        ..._recentPlaces.map((place) => _buildPlaceTile(place)),

        const SizedBox(height: 16),

        // Suggestions header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Try searching for',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Suggestion chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Berlin'),
              _buildSuggestionChip('Paris'),
              _buildSuggestionChip('Amsterdam'),
              _buildSuggestionChip('Milan'),
              _buildSuggestionChip('Barcelona'),
              _buildSuggestionChip('Vienna'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonTile(),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final distance = _calculateDistance(result.location);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _getIconForType(result.type),
                color: Colors.grey[700],
                size: 22,
              ),
            ),
            title: Text(
              result.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                if (distance != null) ...[
                  Text(
                    distance < 1
                        ? '${(distance * 1000).round()} m'
                        : '${distance.round()} km',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    ' · ',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
                Expanded(
                  child: Text(
                    result.displayName,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onTap: () => _selectResult(result),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPlaceTile(_RecentPlace place) {
    final distance = _calculateDistance(place.location);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(place.icon, color: Colors.grey[700], size: 22),
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            if (distance != null) ...[
              Text(
                '${distance.round()} km',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              Text(' · ', style: TextStyle(color: Colors.grey[400])),
            ],
            Expanded(
              child: Text(
                place.address,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onTap: () => _selectRecentPlace(place),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearchChanged(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSkeletonTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
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

class _RecentPlace {
  final String name;
  final String address;
  final IconData icon;
  final LatLng location;

  _RecentPlace({
    required this.name,
    required this.address,
    required this.icon,
    required this.location,
  });
}
