import 'package:flutter/material.dart';
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
      body: Stack(
        children: [
          // Real OpenStreetMap using flutter_map
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
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.truckflow.mobile',
                maxZoom: 19,
              ),
              // Route polyline
              if (mapState.hasRoute && mapState.activeRoute!.path.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.activeRoute!.path,
                      color: Colors.blue,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              // Markers for hazards
              if (mapState.hazards.isNotEmpty)
                MarkerLayer(
                  markers: mapState.hazards.map((hazard) {
                    return Marker(
                      point: LatLng(hazard.lat, hazard.lng),
                      width: 40,
                      height: 40,
                      child: _HazardMarker(type: hazard.type.value),
                    );
                  }).toList(),
                ),
              // Markers for truck parking
              if (mapState.truckParks.isNotEmpty)
                MarkerLayer(
                  markers: mapState.truckParks.map((park) {
                    return Marker(
                      point: LatLng(park.lat, park.lng),
                      width: 40,
                      height: 40,
                      child: const _ParkingMarker(),
                    );
                  }).toList(),
                ),
              // Current location marker
              if (mapState.currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapState.currentLocation!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar - Speed & driving time
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Current speed
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${mapState.currentSpeed.toInt()}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const Text('km/h', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Speed limit
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${mapState.speedLimit}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Driving time remaining
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getDrivingTimeColor(mapState.drivingTimeRemaining),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDrivingTime(mapState.drivingTimeRemaining),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Text('until break', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search bar
          Positioned(
            bottom: 160,
            left: 16,
            right: 16,
            child: Card(
              child: InkWell(
                onTap: () {
                  context.push('/route');
                },
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Where to?', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick action buttons
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              children: [
                // Center on location button
                FloatingActionButton.small(
                  heroTag: 'center',
                  onPressed: () async {
                    if (mapState.currentLocation != null) {
                      _mapController.move(mapState.currentLocation!, 14.0);
                    } else {
                      // Try to get current location
                      final trackingService = ref.read(locationTrackingProvider);
                      await trackingService.centerOnCurrentLocation();
                      final newLocation = ref.read(mapProvider).currentLocation;
                      if (newLocation != null) {
                        _mapController.move(newLocation, 14.0);
                      }
                    }
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'parking',
                  onPressed: () {
                    ref.read(mapProvider.notifier).loadNearbyParking();
                  },
                  child: const Icon(Icons.local_parking),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fuel',
                  onPressed: () {},
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.local_gas_station),
                ),
              ],
            ),
          ),

          // Report hazard button
          Positioned(
            bottom: 80,
            left: 16,
            child: FloatingActionButton.extended(
              heroTag: 'hazard',
              onPressed: () {
                _showHazardReportSheet(context);
              },
              backgroundColor: Colors.red,
              icon: const Icon(Icons.warning),
              label: const Text('Report'),
            ),
          ),

          // Child widget (for nested routes)
          if (widget.child != null) widget.child!,
        ],
      ),
      bottomNavigationBar: TruckFlowBottomNavBar(currentIndex: selectedIndex),
    );
  }

  Color _getDrivingTimeColor(Duration remaining) {
    if (remaining.inMinutes <= 30) return Colors.red;
    if (remaining.inMinutes <= 60) return Colors.orange;
    return Colors.green;
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
      builder: (context) => _HazardReportSheet(
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
        const SnackBar(content: Text('Hazard reported. Thank you!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    }
  }
}

class _HazardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String type;
  final void Function(String) onTap;

  const _HazardButton({
    required this.icon,
    required this.label,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HazardMarker extends StatelessWidget {
  final String type;

  const _HazardMarker({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'police':
        icon = Icons.local_police;
        color = Colors.blue;
        break;
      case 'speed_camera':
        icon = Icons.camera_alt;
        color = Colors.orange;
        break;
      case 'accident':
        icon = Icons.car_crash;
        color = Colors.red;
        break;
      case 'road_work':
        icon = Icons.construction;
        color = Colors.amber;
        break;
      case 'road_closure':
        icon = Icons.block;
        color = Colors.red;
        break;
      case 'weather':
        icon = Icons.cloud;
        color = Colors.grey;
        break;
      case 'border_delay':
        icon = Icons.security;
        color = Colors.purple;
        break;
      default:
        icon = Icons.warning;
        color = Colors.orange;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _ParkingMarker extends StatelessWidget {
  const _ParkingMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.local_parking, color: Colors.white, size: 24),
    );
  }
}

class _HazardReportSheet extends StatefulWidget {
  final VoiceInputService voiceService;
  final void Function(String type) onReport;

  const _HazardReportSheet({
    required this.voiceService,
    required this.onReport,
  });

  @override
  State<_HazardReportSheet> createState() => _HazardReportSheetState();
}

class _HazardReportSheetState extends State<_HazardReportSheet> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Report Hazard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              // Voice input button
              GestureDetector(
                onTap: _toggleVoice,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isListening ? 'Listening...' : 'Voice',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Voice input feedback
          if (_voiceText.isNotEmpty || _isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isListening ? Colors.blue : Colors.grey[300]!,
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Say the hazard type (e.g., "Police ahead")',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  if (_voiceText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"$_voiceText"', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                  if (_detectedHazard != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Detected: ${_getHazardLabel(_detectedHazard!)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onReport(_detectedHazard!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Report'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Manual selection
          if (!_isListening)
            const Text(
              'Or tap to report:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HazardButton(icon: Icons.local_police, label: 'Police', type: 'police', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.camera_alt, label: 'Camera', type: 'camera', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.car_crash, label: 'Accident', type: 'accident', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.construction, label: 'Road Works', type: 'road_works', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.block, label: 'Closed', type: 'road_closure', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.warning, label: 'Hazard', type: 'road_hazard', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.cloud, label: 'Weather', type: 'weather', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
              _HazardButton(icon: Icons.security, label: 'Border', type: 'border_delay', onTap: (t) { Navigator.pop(context); widget.onReport(t); }),
            ],
          ),
          const SizedBox(height: 16),
        ],
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
