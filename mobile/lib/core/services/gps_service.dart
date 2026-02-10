import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});

final locationStreamProvider = StreamProvider<GpsPosition>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.positionStream;
});

class GpsPosition {
  final LatLng location;
  final double speedKmh;
  final double heading;
  final double accuracy;
  final DateTime timestamp;

  GpsPosition({
    required this.location,
    required this.speedKmh,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  factory GpsPosition.fromGeolocator(Position position) {
    // Convert m/s to km/h
    final speedKmh = (position.speed * 3.6).clamp(0.0, 200.0);

    return GpsPosition(
      location: LatLng(position.latitude, position.longitude),
      speedKmh: speedKmh,
      heading: position.heading,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': location.latitude,
      'lng': location.longitude,
      'speed_kmh': speedKmh,
      'heading': heading,
      'accuracy_m': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class GpsService {
  StreamSubscription<Position>? _positionSubscription;
  final _positionController = StreamController<GpsPosition>.broadcast();

  Stream<GpsPosition> get positionStream => _positionController.stream;

  GpsPosition? _lastPosition;
  GpsPosition? get lastPosition => _lastPosition;

  // Activity state detection (from spec)
  String _activityState = 'unknown';
  String get activityState => _activityState;
  DateTime? _stoppedSince;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<GpsPosition?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Location timeout'),
      );
      final gpsPosition = GpsPosition.fromGeolocator(position);
      _lastPosition = gpsPosition;
      _updateActivityState(gpsPosition);
      return gpsPosition;
    } catch (e) {
      return null;
    }
  }

  Future<void> startTracking({
    bool highAccuracy = true,
    int intervalMs = 5000,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await stopTracking();

    // Adaptive GPS frequency based on activity
    // High precision when navigating: every 5 sec
    // Medium when driving without nav: every 30 sec
    // Low when parked: every 5 min
    final settings = AndroidSettings(
      accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
      distanceFilter: 10, // minimum 10 meters between updates
      intervalDuration: Duration(milliseconds: intervalMs),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'TruckFlow',
        notificationText: 'Tracking your location for navigation',
        enableWakeLock: true,
      ),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        final gpsPosition = GpsPosition.fromGeolocator(position);
        _lastPosition = gpsPosition;
        _updateActivityState(gpsPosition);
        _positionController.add(gpsPosition);
      },
      onError: (error) {
        // Handle GPS errors silently
      },
    );
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Activity state detection algorithm from spec
  void _updateActivityState(GpsPosition position) {
    final speed = position.speedKmh;

    if (speed > 5) {
      _activityState = 'driving';
      _stoppedSince = null;
    } else {
      // Speed < 5 km/h - determine stopped state
      _stoppedSince ??= position.timestamp;
      final stoppedDuration = position.timestamp.difference(_stoppedSince!);

      if (stoppedDuration.inMinutes < 5) {
        _activityState = 'stopped_brief'; // traffic light, queue
      } else if (stoppedDuration.inMinutes < 30) {
        _activityState = 'stopped_short'; // fuel, brief rest
      } else {
        _activityState = 'stopped_long'; // loading, break
      }

      // Parked detection: very low speed and minimal position drift
      if (speed < 2) {
        _activityState = 'parked';
      }
    }
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
