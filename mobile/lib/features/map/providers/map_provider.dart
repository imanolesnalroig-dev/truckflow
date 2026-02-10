import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/hazard.dart';
import '../../../core/models/truck_park.dart';
import '../../../core/models/route.dart';

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref);
});

class MapState {
  final LatLng? currentLocation;
  final double currentSpeed;
  final int speedLimit;
  final Duration drivingTimeRemaining;
  final List<Hazard> hazards;
  final List<TruckPark> truckParks;
  final TruckRoute? activeRoute;
  final bool isNavigating;
  final bool isLoading;
  final String? error;

  MapState({
    this.currentLocation,
    this.currentSpeed = 0,
    this.speedLimit = 80,
    this.drivingTimeRemaining = const Duration(hours: 4, minutes: 30),
    this.hazards = const [],
    this.truckParks = const [],
    this.activeRoute,
    this.isNavigating = false,
    this.isLoading = false,
    this.error,
  });

  MapState copyWith({
    LatLng? currentLocation,
    double? currentSpeed,
    int? speedLimit,
    Duration? drivingTimeRemaining,
    List<Hazard>? hazards,
    List<TruckPark>? truckParks,
    TruckRoute? activeRoute,
    bool? isNavigating,
    bool? isLoading,
    String? error,
    bool clearRoute = false,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      speedLimit: speedLimit ?? this.speedLimit,
      drivingTimeRemaining: drivingTimeRemaining ?? this.drivingTimeRemaining,
      hazards: hazards ?? this.hazards,
      truckParks: truckParks ?? this.truckParks,
      activeRoute: clearRoute ? null : (activeRoute ?? this.activeRoute),
      isNavigating: isNavigating ?? this.isNavigating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasRoute => activeRoute != null;
}

class MapNotifier extends StateNotifier<MapState> {
  final Ref _ref;

  MapNotifier(this._ref) : super(MapState());

  ApiClient get _apiClient => _ref.read(apiClientProvider);

  void updateLocation(LatLng location, {double? speed}) {
    state = state.copyWith(
      currentLocation: location,
      currentSpeed: speed ?? state.currentSpeed,
    );
  }

  void updateSpeed(double speed) {
    state = state.copyWith(currentSpeed: speed);
  }

  void updateSpeedLimit(int limit) {
    state = state.copyWith(speedLimit: limit);
  }

  void updateDrivingTime(Duration remaining) {
    state = state.copyWith(drivingTimeRemaining: remaining);
  }

  Future<void> loadNearbyHazards() async {
    if (state.currentLocation == null) return;

    try {
      final response = await _apiClient.getHazards(
        lat: state.currentLocation!.latitude,
        lng: state.currentLocation!.longitude,
        radiusKm: 50,
      );

      if (response.data is List) {
        final hazards = (response.data as List)
            .map((json) => Hazard.fromJson(json))
            .where((h) => !h.isExpired && h.isActive)
            .toList();
        state = state.copyWith(hazards: hazards);
      }
    } catch (e) {
      // Silently fail - hazards are non-critical
    }
  }

  Future<void> loadNearbyParking() async {
    if (state.currentLocation == null) {
      // Use default location if no GPS
      await _loadParkingAt(50.0, 10.0);
      return;
    }

    await _loadParkingAt(
      state.currentLocation!.latitude,
      state.currentLocation!.longitude,
    );
  }

  Future<void> _loadParkingAt(double lat, double lng) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.searchParking(
        lat: lat,
        lng: lng,
        radiusKm: 100,
      );

      if (response.data is List) {
        final parks = (response.data as List)
            .map((json) => TruckPark.fromJson(json))
            .toList();
        state = state.copyWith(truckParks: parks, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> reportHazard({
    required String type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      await _apiClient.reportHazard({
        'hazardType': type,
        'lat': latitude,
        'lng': longitude,
        if (description != null) 'description': description,
      });

      // Reload hazards after reporting
      await loadNearbyHazards();
    } catch (e) {
      state = state.copyWith(error: 'Failed to report hazard');
    }
  }

  Future<void> confirmHazard(String hazardId) async {
    try {
      await _apiClient.confirmHazard(hazardId);
      await loadNearbyHazards();
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> denyHazard(String hazardId) async {
    try {
      await _apiClient.denyHazard(hazardId);
      await loadNearbyHazards();
    } catch (e) {
      // Silently fail
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setActiveRoute(TruckRoute? route) {
    state = state.copyWith(activeRoute: route);
  }

  void startNavigation(TruckRoute route) {
    state = state.copyWith(activeRoute: route, isNavigating: true);
  }

  void stopNavigation() {
    state = state.copyWith(clearRoute: true, isNavigating: false);
  }
}
