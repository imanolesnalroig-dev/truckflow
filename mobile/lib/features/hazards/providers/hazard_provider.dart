import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/hazard.dart';

class HazardNotifier extends StateNotifier<AsyncValue<List<Hazard>>> {
  final ApiClient _apiClient;

  HazardNotifier(this._apiClient) : super(const AsyncValue.data([]));

  Future<void> fetchHazards({
    required double lat,
    required double lng,
    int radiusKm = 50,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getHazards(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      final hazards = (response.data['hazards'] as List)
          .map((json) => Hazard.fromJson(json))
          .where((h) => !h.isExpired && h.isActive)
          .toList();
      state = AsyncValue.data(hazards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> reportHazard({
    required double lat,
    required double lng,
    required HazardType type,
    String? description,
    HazardSeverity severity = HazardSeverity.medium,
    int? direction,
  }) async {
    try {
      await _apiClient.reportHazard({
        'lat': lat,
        'lng': lng,
        'hazardType': type.value,
        'description': description,
        'severity': severity.value,
        'direction': direction,
      });
      // Refresh hazards after reporting
      await fetchHazards(lat: lat, lng: lng);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmHazard(String hazardId, double lat, double lng) async {
    try {
      await _apiClient.confirmHazard(hazardId);
      await fetchHazards(lat: lat, lng: lng);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> denyHazard(String hazardId, double lat, double lng) async {
    try {
      await _apiClient.denyHazard(hazardId);
      await fetchHazards(lat: lat, lng: lng);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final hazardProvider = StateNotifierProvider<HazardNotifier, AsyncValue<List<Hazard>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HazardNotifier(apiClient);
});

// Current user location provider (placeholder - will be updated by geolocator)
final currentLocationProvider = StateProvider<({double lat, double lng})?>((ref) => null);
