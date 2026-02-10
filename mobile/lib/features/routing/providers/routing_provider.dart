import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/route.dart';

final routingProvider = StateNotifierProvider<RoutingNotifier, RoutingState>((ref) {
  return RoutingNotifier(ref);
});

class RoutingState {
  final TruckRoute? currentRoute;
  final List<TruckRoute> alternativeRoutes;
  final bool isCalculating;
  final String? error;
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> waypoints;
  final bool avoidTolls;
  final bool avoidFerries;
  final bool includeRestStops;

  RoutingState({
    this.currentRoute,
    this.alternativeRoutes = const [],
    this.isCalculating = false,
    this.error,
    this.origin,
    this.destination,
    this.waypoints = const [],
    this.avoidTolls = false,
    this.avoidFerries = false,
    this.includeRestStops = true,
  });

  RoutingState copyWith({
    TruckRoute? currentRoute,
    List<TruckRoute>? alternativeRoutes,
    bool? isCalculating,
    String? error,
    LatLng? origin,
    LatLng? destination,
    List<LatLng>? waypoints,
    bool? avoidTolls,
    bool? avoidFerries,
    bool? includeRestStops,
    bool clearRoute = false,
    bool clearError = false,
  }) {
    return RoutingState(
      currentRoute: clearRoute ? null : (currentRoute ?? this.currentRoute),
      alternativeRoutes: alternativeRoutes ?? this.alternativeRoutes,
      isCalculating: isCalculating ?? this.isCalculating,
      error: clearError ? null : (error ?? this.error),
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      waypoints: waypoints ?? this.waypoints,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      avoidFerries: avoidFerries ?? this.avoidFerries,
      includeRestStops: includeRestStops ?? this.includeRestStops,
    );
  }

  bool get hasRoute => currentRoute != null;
  bool get canCalculate => origin != null && destination != null;
}

class RoutingNotifier extends StateNotifier<RoutingState> {
  final Ref _ref;

  RoutingNotifier(this._ref) : super(RoutingState());

  ApiClient get _apiClient => _ref.read(apiClientProvider);

  void setOrigin(LatLng origin) {
    state = state.copyWith(origin: origin, clearRoute: true, clearError: true);
  }

  void setDestination(LatLng destination) {
    state = state.copyWith(destination: destination, clearRoute: true, clearError: true);
  }

  void addWaypoint(LatLng waypoint) {
    final waypoints = [...state.waypoints, waypoint];
    state = state.copyWith(waypoints: waypoints, clearRoute: true);
  }

  void removeWaypoint(int index) {
    final waypoints = [...state.waypoints]..removeAt(index);
    state = state.copyWith(waypoints: waypoints, clearRoute: true);
  }

  void setAvoidTolls(bool value) {
    state = state.copyWith(avoidTolls: value, clearRoute: true);
  }

  void setAvoidFerries(bool value) {
    state = state.copyWith(avoidFerries: value, clearRoute: true);
  }

  void setIncludeRestStops(bool value) {
    state = state.copyWith(includeRestStops: value);
  }

  Future<void> calculateRoute({String? truckProfileId}) async {
    if (!state.canCalculate) {
      state = state.copyWith(error: 'Please set origin and destination');
      return;
    }

    state = state.copyWith(isCalculating: true, clearError: true);

    try {
      final request = RouteRequest(
        origin: state.origin!,
        destination: state.destination!,
        waypoints: state.waypoints,
        truckProfileId: truckProfileId,
        avoidTolls: state.avoidTolls,
        avoidFerries: state.avoidFerries,
      );

      final response = await _apiClient.calculateRoute(request.toJson());

      if (response.data != null) {
        final route = TruckRoute.fromJson(response.data);
        state = state.copyWith(
          currentRoute: route,
          isCalculating: false,
        );
      } else {
        state = state.copyWith(
          isCalculating: false,
          error: 'Failed to calculate route',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isCalculating: false,
        error: e.toString(),
      );
    }
  }

  void clearRoute() {
    state = state.copyWith(clearRoute: true, clearError: true);
  }

  void clearAll() {
    state = RoutingState();
  }
}
