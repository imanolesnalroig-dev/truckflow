import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/truck_profile.dart';

class TruckProfileNotifier extends StateNotifier<AsyncValue<List<TruckProfile>>> {
  final ApiClient _apiClient;

  TruckProfileNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getTruckProfiles();
      final profiles = (response.data['trucks'] as List)
          .map((json) => TruckProfile.fromJson(json))
          .toList();
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createProfile(TruckProfile profile) async {
    try {
      await _apiClient.createTruckProfile(profile.toJson());
      await fetchProfiles();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(TruckProfile profile) async {
    try {
      await _apiClient.updateTruckProfile(profile.id, profile.toJson());
      await fetchProfiles();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProfile(String id) async {
    try {
      await _apiClient.deleteTruckProfile(id);
      await fetchProfiles();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setDefault(String id) async {
    try {
      // Update the profile to be default
      final profiles = state.value ?? [];
      final profile = profiles.firstWhere((p) => p.id == id);
      await _apiClient.updateTruckProfile(id, {...profile.toJson(), 'isDefault': true});
      await fetchProfiles();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final truckProfilesProvider = StateNotifierProvider<TruckProfileNotifier, AsyncValue<List<TruckProfile>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TruckProfileNotifier(apiClient);
});

final defaultTruckProfileProvider = Provider<TruckProfile?>((ref) {
  final profiles = ref.watch(truckProfilesProvider);
  return profiles.when(
    data: (list) => list.isEmpty ? null : list.firstWhere(
      (p) => p.isDefault,
      orElse: () => list.first,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

final selectedTruckProfileProvider = StateProvider<TruckProfile?>((ref) {
  return ref.watch(defaultTruckProfileProvider);
});
