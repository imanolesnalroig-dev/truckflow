import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/gps_service.dart';
import '../../../core/services/telemetry_service.dart';
import 'map_provider.dart';

// Provider that starts GPS tracking and syncs with map
final locationTrackingProvider = Provider<LocationTrackingService>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);
  final mapNotifier = ref.watch(mapProvider.notifier);

  final service = LocationTrackingService(gpsService, telemetryService, mapNotifier);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Auto-start provider - initialize this in the app to auto-start tracking
final locationAutoStartProvider = FutureProvider<bool>((ref) async {
  final trackingService = ref.watch(locationTrackingProvider);
  return await trackingService.initialize();
});

class LocationTrackingService {
  final GpsService _gpsService;
  final TelemetryService _telemetryService;
  final MapNotifier _mapNotifier;

  StreamSubscription<GpsPosition>? _positionSubscription;
  bool _isInitialized = false;

  LocationTrackingService(
    this._gpsService,
    this._telemetryService,
    this._mapNotifier,
  );

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request permissions
    final hasPermission = await _gpsService.requestPermission();
    if (!hasPermission) return false;

    // Get initial position
    final initialPosition = await _gpsService.getCurrentPosition();
    if (initialPosition != null) {
      _mapNotifier.updateLocation(
        initialPosition.location,
        speed: initialPosition.speedKmh,
      );
    }

    // Start continuous tracking
    await _gpsService.startTracking(
      highAccuracy: true,
      intervalMs: 5000, // 5 seconds while navigating
    );

    // Start telemetry collection
    _telemetryService.startCollecting();

    // Listen for position updates and sync with map
    _positionSubscription = _gpsService.positionStream.listen((position) {
      _mapNotifier.updateLocation(position.location, speed: position.speedKmh);

      // Update activity state for compliance tracking
      _updateComplianceTracking(position);
    });

    _isInitialized = true;
    return true;
  }

  void _updateComplianceTracking(GpsPosition position) {
    // The compliance provider would listen to activity changes
    // For now, just log the activity state
    final state = _gpsService.activityState;

    // When driving, decrease remaining time
    // When stopped_long or parked, this counts as break/rest
    // This will be connected to the compliance provider
  }

  Future<void> centerOnCurrentLocation() async {
    final position = await _gpsService.getCurrentPosition();
    if (position != null) {
      _mapNotifier.updateLocation(position.location, speed: position.speedKmh);
    }
  }

  LatLng? get currentLocation => _gpsService.lastPosition?.location;

  void dispose() {
    _positionSubscription?.cancel();
    _gpsService.stopTracking();
    _telemetryService.stopCollecting();
  }
}
