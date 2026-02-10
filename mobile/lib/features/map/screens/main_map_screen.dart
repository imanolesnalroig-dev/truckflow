import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/services/voice_input_service.dart';
import '../providers/map_provider.dart';
import '../providers/location_provider.dart';

class MainMapScreen extends ConsumerStatefulWidget {
  final Widget? child;

  const MainMapScreen({super.key, this.child});

  @override
  ConsumerState<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends ConsumerState<MainMapScreen> {
  final MapController _mapController = MapController();
  final VoiceInputService _voiceService = VoiceInputService();
  bool _locationInitialized = false;

  // Default center: Central Europe (good starting point for truck drivers)
  static const LatLng _defaultCenter = LatLng(50.0, 10.0);
  static const double _defaultZoom = 5.0;

  @override
  void initState() {
    super.initState();
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    // Initialize location tracking after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    if (_locationInitialized) return;

    final trackingService = ref.read(locationTrackingProvider);
    final success = await trackingService.initialize();

    if (success && mounted) {
      setState(() {
        _locationInitialized = true;
      });

      // Load nearby hazards and parking after location is initialized
      ref.read(mapProvider.notifier).loadNearbyHazards();
      ref.read(mapProvider.notifier).loadNearbyParking();
    }
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/parking')) return 1;
    if (location.startsWith('/compliance')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final mapState = ref.watch(mapProvider);

    // For non-map tabs, show the child directly with bottom nav
    if (widget.child != null && selectedIndex != 0) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: TruckFlowBottomNavBar(currentIndex: selectedIndex),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Modern map with CartoDB Voyager tiles (cleaner look)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.currentLocation ?? _defaultCenter,
              initialZoom: mapState.currentLocation != null ? 14.0 : _defaultZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // Can be used to add markers or get location info
              },
            ),
            children: [
              // Modern map tiles - CartoDB Voyager (cleaner, more modern look)
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.truckflow.mobile',
                maxZoom: 20,
                retinaMode: true,
              ),
              // Route polyline with gradient-like effect
              if (mapState.hasRoute && mapState.activeRoute!.path.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Shadow for depth
                    Polyline(
                      points: mapState.activeRoute!.path,
                      color: Colors.black.withOpacity(0.2),
                      strokeWidth: 10.0,
                    ),
                    // Main route line
                    Polyline(
                      points: mapState.activeRoute!.path,
                      color: const Color(0xFF4285F4),
                      strokeWidth: 6.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              // Markers for hazards
              if (mapState.hazards.isNotEmpty)
                MarkerLayer(
                  markers: mapState.hazards.map((hazard) {
                    return Marker(
                      point: LatLng(hazard.lat, hazard.lng),
                      width: 44,
                      height: 44,
                      child: _ModernHazardMarker(type: hazard.type.value),
                    );
                  }).toList(),
                ),
              // Markers for truck parking
              if (mapState.truckParks.isNotEmpty)
                MarkerLayer(
                  markers: mapState.truckParks.map((park) {
                    return Marker(
                      point: LatLng(park.lat, park.lng),
                      width: 44,
                      height: 44,
                      child: const _ModernParkingMarker(),
                    );
                  }).toList(),
                ),
              // Current location marker - Uber/Google style
              if (mapState.currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapState.currentLocation!,
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing circle effect
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4285F4).withOpacity(0.15),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4285F4).withOpacity(0.2),
                            ),
                          ),
                          // Inner dot
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top status bar - Modern glassmorphism style
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildModernStatusBar(mapState),
          ),

          // Modern search bar - Uber/Google Maps style
          Positioned(
            bottom: 180,
            left: 20,
            right: 20,
            child: _buildModernSearchBar(),
          ),

          // Quick action buttons - Modern floating style
          Positioned(
            bottom: 100,
            right: 20,
            child: _buildQuickActions(mapState),
          ),

          // Report hazard button - Modern pill style
          Positioned(
            bottom: 100,
            left: 20,
            child: _buildReportButton(),
          ),

          // Child widget (for nested routes)
          if (widget.child != null) widget.child!,
        ],
      ),
      bottomNavigationBar: TruckFlowBottomNavBar(currentIndex: selectedIndex),
    );
  }

  Widget _buildModernStatusBar(MapState mapState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Current speed - Large and prominent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${mapState.currentSpeed.toInt()}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'km/h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Speed limit sign - European style
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE53935), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${mapState.speedLimit}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Driving time remaining - Compliance indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getDrivingTimeBackgroundColor(mapState.drivingTimeRemaining),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: _getDrivingTimeColor(mapState.drivingTimeRemaining),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDrivingTime(mapState.drivingTimeRemaining),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _getDrivingTimeColor(mapState.drivingTimeRemaining),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'until break',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getDrivingTimeColor(mapState.drivingTimeRemaining).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return GestureDetector(
      onTap: () => context.push('/route'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF4285F4),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where to?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Search destination, warehouse, or parking',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.mic_rounded,
                color: Colors.grey[600],
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(MapState mapState) {
    return Column(
      children: [
        // Center on location button
        _buildActionButton(
          icon: Icons.my_location_rounded,
          color: const Color(0xFF4285F4),
          bgColor: Colors.white,
          onTap: () async {
            if (mapState.currentLocation != null) {
              _mapController.move(mapState.currentLocation!, 14.0);
            } else {
              final trackingService = ref.read(locationTrackingProvider);
              await trackingService.centerOnCurrentLocation();
              final newLocation = ref.read(mapProvider).currentLocation;
              if (newLocation != null) {
                _mapController.move(newLocation, 14.0);
              }
            }
          },
        ),
        const SizedBox(height: 12),
        // Parking button
        _buildActionButton(
          icon: Icons.local_parking_rounded,
          color: Colors.white,
          bgColor: const Color(0xFF34A853),
          onTap: () {
            ref.read(mapProvider.notifier).loadNearbyParking();
          },
        ),
        const SizedBox(height: 12),
        // Fuel button
        _buildActionButton(
          icon: Icons.local_gas_station_rounded,
          color: Colors.white,
          bgColor: const Color(0xFFFF9800),
          onTap: () {
            // TODO: Load nearby fuel stations
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor == Colors.white
                  ? Colors.black.withOpacity(0.1)
                  : bgColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildReportButton() {
    return GestureDetector(
      onTap: () => _showHazardReportSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDrivingTimeColor(Duration remaining) {
    if (remaining.inMinutes <= 30) return const Color(0xFFE53935);
    if (remaining.inMinutes <= 60) return const Color(0xFFFF9800);
    return const Color(0xFF34A853);
  }

  Color _getDrivingTimeBackgroundColor(Duration remaining) {
    if (remaining.inMinutes <= 30) return const Color(0xFFFFEBEE);
    if (remaining.inMinutes <= 60) return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F5E9);
  }

  String _formatDrivingTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  void _showHazardReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernHazardReportSheet(
        voiceService: _voiceService,
        onReport: _reportHazard,
      ),
    );
  }

  void _reportHazard(String type) {
    final mapState = ref.read(mapProvider);
    if (mapState.currentLocation != null) {
      ref.read(mapProvider.notifier).reportHazard(
        type: type,
        latitude: mapState.currentLocation!.latitude,
        longitude: mapState.currentLocation!.longitude,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Hazard reported. Thank you!'),
            ],
          ),
          backgroundColor: const Color(0xFF34A853),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Could not get current location'),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

class _ModernHazardMarker extends StatelessWidget {
  final String type;

  const _ModernHazardMarker({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'police':
        icon = Icons.local_police_rounded;
        color = const Color(0xFF4285F4);
        break;
      case 'speed_camera':
        icon = Icons.camera_alt_rounded;
        color = const Color(0xFFFF9800);
        break;
      case 'accident':
        icon = Icons.car_crash_rounded;
        color = const Color(0xFFE53935);
        break;
      case 'road_work':
        icon = Icons.construction_rounded;
        color = const Color(0xFFFFC107);
        break;
      case 'road_closure':
        icon = Icons.block_rounded;
        color = const Color(0xFFE53935);
        break;
      case 'weather':
        icon = Icons.cloud_rounded;
        color = const Color(0xFF607D8B);
        break;
      case 'border_delay':
        icon = Icons.security_rounded;
        color = const Color(0xFF9C27B0);
        break;
      default:
        icon = Icons.warning_rounded;
        color = const Color(0xFFFF9800);
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _ModernParkingMarker extends StatelessWidget {
  const _ModernParkingMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF34A853),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34A853).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 24),
    );
  }
}

class _ModernHazardReportSheet extends StatefulWidget {
  final VoiceInputService voiceService;
  final void Function(String type) onReport;

  const _ModernHazardReportSheet({
    required this.voiceService,
    required this.onReport,
  });

  @override
  State<_ModernHazardReportSheet> createState() => _ModernHazardReportSheetState();
}

class _ModernHazardReportSheetState extends State<_ModernHazardReportSheet> {
  bool _isListening = false;
  String _voiceText = '';
  String? _detectedHazard;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    await widget.voiceService.initialize();
    widget.voiceService.onTextReceived = (text, isFinal) {
      setState(() {
        _voiceText = text;
        if (isFinal) {
          _detectedHazard = widget.voiceService.parseHazardType(text);
          _isListening = false;
        }
      });
    };
    widget.voiceService.onStatusChanged = (status) {
      if (status == 'done' || status == 'notListening') {
        setState(() => _isListening = false);
      }
    };
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await widget.voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _voiceText = '';
        _detectedHazard = null;
      });
      await widget.voiceService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Report Hazard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                // Voice input button
                GestureDetector(
                  onTap: _toggleVoice,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFFE53935)
                          : const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                              ? const Color(0xFFE53935)
                              : const Color(0xFF4285F4)).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isListening ? 'Listening...' : 'Voice',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Voice input feedback
            if (_voiceText.isNotEmpty || _isListening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFF4285F4).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isListening
                        ? const Color(0xFF4285F4)
                        : Colors.grey[300]!,
                    width: _isListening ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isListening)
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF4285F4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Say the hazard type (e.g., "Police ahead")',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    if (_voiceText.isNotEmpty) ...[
                      if (_isListening) const SizedBox(height: 12),
                      Text(
                        '"$_voiceText"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    if (_detectedHazard != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF34A853),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detected: ${_getHazardLabel(_detectedHazard!)}',
                            style: const TextStyle(
                              color: Color(0xFF34A853),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onReport(_detectedHazard!);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34A853),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Report',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // Manual selection header
            if (!_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Or tap to report:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),

            // Hazard grid - Modern card style
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _ModernHazardButton(
                  icon: Icons.local_police_rounded,
                  label: 'Police',
                  type: 'police',
                  color: const Color(0xFF4285F4),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  type: 'camera',
                  color: const Color(0xFFFF9800),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.car_crash_rounded,
                  label: 'Accident',
                  type: 'accident',
                  color: const Color(0xFFE53935),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.construction_rounded,
                  label: 'Works',
                  type: 'road_works',
                  color: const Color(0xFFFFC107),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.block_rounded,
                  label: 'Closed',
                  type: 'road_closure',
                  color: const Color(0xFFE53935),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.warning_rounded,
                  label: 'Hazard',
                  type: 'road_hazard',
                  color: const Color(0xFFFF9800),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.cloud_rounded,
                  label: 'Weather',
                  type: 'weather',
                  color: const Color(0xFF607D8B),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
                _ModernHazardButton(
                  icon: Icons.security_rounded,
                  label: 'Border',
                  type: 'border_delay',
                  color: const Color(0xFF9C27B0),
                  onTap: (t) { Navigator.pop(context); widget.onReport(t); },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getHazardLabel(String type) {
    switch (type) {
      case 'police': return 'Police';
      case 'camera': return 'Speed Camera';
      case 'accident': return 'Accident';
      case 'road_works': return 'Road Works';
      case 'road_closure': return 'Road Closed';
      case 'road_hazard': return 'Road Hazard';
      case 'weather': return 'Bad Weather';
      case 'border_delay': return 'Border Delay';
      default: return type;
    }
  }
}

class _ModernHazardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String type;
  final Color color;
  final void Function(String) onTap;

  const _ModernHazardButton({
    required this.icon,
    required this.label,
    required this.type,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
