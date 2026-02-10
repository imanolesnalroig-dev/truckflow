import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/compliance_status.dart';

class ComplianceNotifier extends StateNotifier<AsyncValue<ComplianceStatus>> {
  final ApiClient _apiClient;
  Timer? _timer;

  ComplianceNotifier(this._apiClient) : super(AsyncValue.data(ComplianceStatus.initial())) {
    _startTimer();
  }

  void _startTimer() {
    // Update compliance status every minute when driving
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (state.value?.status == DriverStatus.driving) {
        _updateLocalTime();
      }
    });
  }

  void _updateLocalTime() {
    final current = state.value;
    if (current == null) return;

    // Update local time tracking (will be synced with server periodically)
    final newDrivingToday = current.drivingToday + const Duration(minutes: 1);
    final newUntilBreak = current.untilBreakRequired - const Duration(minutes: 1);

    state = AsyncValue.data(ComplianceStatus(
      status: current.status,
      drivingToday: newDrivingToday,
      breakToday: current.breakToday,
      drivingThisWeek: current.drivingThisWeek + const Duration(minutes: 1),
      drivingLastTwoWeeks: current.drivingLastTwoWeeks + const Duration(minutes: 1),
      untilBreakRequired: newUntilBreak.isNegative ? Duration.zero : newUntilBreak,
      untilDailyRestRequired: current.untilDailyRestRequired - const Duration(minutes: 1),
      extendedDaysUsedThisWeek: current.extendedDaysUsedThisWeek,
      reducedRestsUsedThisWeek: current.reducedRestsUsedThisWeek,
      lastDailyRestEnded: current.lastDailyRestEnded,
      lastWeeklyRestEnded: current.lastWeeklyRestEnded,
      isCompliant: newUntilBreak.inMinutes > 0,
      warnings: _calculateWarnings(newUntilBreak, newDrivingToday),
    ));
  }

  List<String> _calculateWarnings(Duration untilBreak, Duration drivingToday) {
    final warnings = <String>[];
    if (untilBreak.inMinutes <= 30) {
      warnings.add('Break required in ${untilBreak.inMinutes} minutes');
    }
    if (drivingToday.inHours >= 8) {
      warnings.add('Approaching daily driving limit');
    }
    return warnings;
  }

  Future<void> fetchStatus() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getComplianceStatus();
      final status = ComplianceStatus.fromJson(response.data);
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startDriving() async {
    try {
      await _apiClient.startDrivingSession();
      await fetchStatus();
    } catch (e) {
      // Continue with local tracking if API fails
      final current = state.value ?? ComplianceStatus.initial();
      state = AsyncValue.data(ComplianceStatus(
        status: DriverStatus.driving,
        drivingToday: current.drivingToday,
        breakToday: current.breakToday,
        drivingThisWeek: current.drivingThisWeek,
        drivingLastTwoWeeks: current.drivingLastTwoWeeks,
        untilBreakRequired: current.untilBreakRequired,
        untilDailyRestRequired: current.untilDailyRestRequired,
        extendedDaysUsedThisWeek: current.extendedDaysUsedThisWeek,
        reducedRestsUsedThisWeek: current.reducedRestsUsedThisWeek,
      ));
    }
  }

  Future<void> startBreak() async {
    try {
      await _apiClient.startBreak();
      await fetchStatus();
    } catch (e) {
      final current = state.value ?? ComplianceStatus.initial();
      state = AsyncValue.data(ComplianceStatus(
        status: DriverStatus.onBreak,
        drivingToday: current.drivingToday,
        breakToday: current.breakToday,
        drivingThisWeek: current.drivingThisWeek,
        drivingLastTwoWeeks: current.drivingLastTwoWeeks,
        untilBreakRequired: current.untilBreakRequired,
        untilDailyRestRequired: current.untilDailyRestRequired,
        extendedDaysUsedThisWeek: current.extendedDaysUsedThisWeek,
        reducedRestsUsedThisWeek: current.reducedRestsUsedThisWeek,
      ));
    }
  }

  Future<void> endBreak() async {
    try {
      await _apiClient.endBreak();
      await fetchStatus();
    } catch (e) {
      final current = state.value ?? ComplianceStatus.initial();
      state = AsyncValue.data(ComplianceStatus(
        status: DriverStatus.driving,
        drivingToday: current.drivingToday,
        breakToday: current.breakToday,
        drivingThisWeek: current.drivingThisWeek,
        drivingLastTwoWeeks: current.drivingLastTwoWeeks,
        // Reset break timer after 45+ min break
        untilBreakRequired: current.breakToday.inMinutes >= 45
            ? const Duration(hours: 4, minutes: 30)
            : current.untilBreakRequired,
        untilDailyRestRequired: current.untilDailyRestRequired,
        extendedDaysUsedThisWeek: current.extendedDaysUsedThisWeek,
        reducedRestsUsedThisWeek: current.reducedRestsUsedThisWeek,
      ));
    }
  }

  Future<void> stopDriving() async {
    try {
      await _apiClient.endDrivingSession();
      await fetchStatus();
    } catch (e) {
      final current = state.value ?? ComplianceStatus.initial();
      state = AsyncValue.data(ComplianceStatus(
        status: DriverStatus.resting,
        drivingToday: current.drivingToday,
        breakToday: current.breakToday,
        drivingThisWeek: current.drivingThisWeek,
        drivingLastTwoWeeks: current.drivingLastTwoWeeks,
        untilBreakRequired: current.untilBreakRequired,
        untilDailyRestRequired: current.untilDailyRestRequired,
        extendedDaysUsedThisWeek: current.extendedDaysUsedThisWeek,
        reducedRestsUsedThisWeek: current.reducedRestsUsedThisWeek,
      ));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final complianceProvider = StateNotifierProvider<ComplianceNotifier, AsyncValue<ComplianceStatus>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplianceNotifier(apiClient);
});
