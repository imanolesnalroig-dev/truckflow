import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/truck_park.dart';
import '../models/hazard.dart';
import '../models/compliance_status.dart';

/// Offline storage service using Hive for local data persistence.
/// Stores data as JSON strings to avoid needing TypeAdapters.
class OfflineStorageService {
  static const String _parkingBoxName = 'parking';
  static const String _hazardsBoxName = 'hazards';
  static const String _routesBoxName = 'routes';
  static const String _complianceBoxName = 'compliance';
  static const String _settingsBoxName = 'settings';
  static const String _pendingUploadsBoxName = 'pending_uploads';

  late Box<String> _parkingBox;
  late Box<String> _hazardsBox;
  late Box<String> _routesBox;
  late Box<String> _complianceBox;
  late Box<String> _settingsBox;
  late Box<String> _pendingUploadsBox;

  bool _isInitialized = false;

  /// Initialize Hive and open all boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _parkingBox = await Hive.openBox<String>(_parkingBoxName);
    _hazardsBox = await Hive.openBox<String>(_hazardsBoxName);
    _routesBox = await Hive.openBox<String>(_routesBoxName);
    _complianceBox = await Hive.openBox<String>(_complianceBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
    _pendingUploadsBox = await Hive.openBox<String>(_pendingUploadsBoxName);

    _isInitialized = true;
  }

  // ============ Parking ============

  /// Save parking locations for offline access
  Future<void> saveParkingLocations(List<TruckPark> parks) async {
    await _parkingBox.put(
      'all_parking',
      jsonEncode(parks.map((p) => p.toJson()).toList()),
    );
    await _parkingBox.put('last_updated', DateTime.now().toIso8601String());
  }

  /// Get cached parking locations
  List<TruckPark> getCachedParking() {
    final data = _parkingBox.get('all_parking');
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => TruckPark.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if parking data is stale (older than 24 hours)
  bool isParkingDataStale() {
    final lastUpdated = _parkingBox.get('last_updated');
    if (lastUpdated == null) return true;

    final date = DateTime.parse(lastUpdated);
    return DateTime.now().difference(date).inHours > 24;
  }

  // ============ Hazards ============

  /// Save hazards for offline access
  Future<void> saveHazards(List<Hazard> hazards) async {
    await _hazardsBox.put(
      'active_hazards',
      jsonEncode(hazards.map((h) => h.toJson()).toList()),
    );
    await _hazardsBox.put('last_updated', DateTime.now().toIso8601String());
  }

  /// Get cached hazards
  List<Hazard> getCachedHazards() {
    final data = _hazardsBox.get('active_hazards');
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList
          .map((json) => Hazard.fromJson(json))
          .where((h) => !h.isExpired && h.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Queue a hazard report for upload when online
  Future<void> queueHazardReport(Map<String, dynamic> hazardData) async {
    final pending = _getPendingUploads('hazard_reports');
    pending.add(hazardData);
    await _pendingUploadsBox.put('hazard_reports', jsonEncode(pending));
  }

  // ============ Routes ============

  /// Save a recent route for offline access
  Future<void> saveRecentRoute(String routeId, Map<String, dynamic> routeData) async {
    await _routesBox.put(routeId, jsonEncode(routeData));

    // Keep track of recent route IDs (max 10)
    final recentIds = _getRecentRouteIds();
    if (!recentIds.contains(routeId)) {
      recentIds.insert(0, routeId);
      if (recentIds.length > 10) {
        final removedId = recentIds.removeLast();
        await _routesBox.delete(removedId);
      }
      await _routesBox.put('recent_ids', jsonEncode(recentIds));
    }
  }

  /// Get a cached route by ID
  Map<String, dynamic>? getCachedRoute(String routeId) {
    final data = _routesBox.get(routeId);
    if (data == null) return null;

    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  /// Get recent route IDs
  List<String> _getRecentRouteIds() {
    final data = _routesBox.get('recent_ids');
    if (data == null) return [];
    try {
      return List<String>.from(jsonDecode(data));
    } catch (e) {
      return [];
    }
  }

  // ============ Compliance ============

  /// Save compliance status for offline access
  Future<void> saveComplianceStatus(ComplianceStatus status) async {
    await _complianceBox.put('current_status', jsonEncode(status.toJson()));
    await _complianceBox.put('last_updated', DateTime.now().toIso8601String());
  }

  /// Get cached compliance status
  ComplianceStatus? getCachedComplianceStatus() {
    final data = _complianceBox.get('current_status');
    if (data == null) return null;

    try {
      return ComplianceStatus.fromJson(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  /// Save driving session data for later sync
  Future<void> saveDrivingSession(Map<String, dynamic> sessionData) async {
    final sessions = _getPendingUploads('driving_sessions');
    sessions.add(sessionData);
    await _pendingUploadsBox.put('driving_sessions', jsonEncode(sessions));
  }

  // ============ Telemetry ============

  /// Queue telemetry data for upload when online
  Future<void> queueTelemetryBatch(List<Map<String, dynamic>> pings) async {
    final pending = _getPendingUploads('telemetry');
    pending.addAll(pings);
    await _pendingUploadsBox.put('telemetry', jsonEncode(pending));
  }

  /// Get pending telemetry uploads
  List<Map<String, dynamic>> getPendingTelemetry() {
    return _getPendingUploads('telemetry').cast<Map<String, dynamic>>();
  }

  /// Clear telemetry after successful upload
  Future<void> clearTelemetryQueue() async {
    await _pendingUploadsBox.delete('telemetry');
  }

  // ============ Settings ============

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, jsonEncode(value));
  }

  /// Get a setting
  T? getSetting<T>(String key) {
    final data = _settingsBox.get(key);
    if (data == null) return null;
    try {
      return jsonDecode(data) as T?;
    } catch (e) {
      return null;
    }
  }

  /// Save truck profile for offline use
  Future<void> saveTruckProfile(Map<String, dynamic> profile) async {
    await _settingsBox.put('truck_profile', jsonEncode(profile));
  }

  /// Get cached truck profile
  Map<String, dynamic>? getCachedTruckProfile() {
    final data = _settingsBox.get('truck_profile');
    if (data == null) return null;
    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  // ============ Pending Uploads ============

  List<dynamic> _getPendingUploads(String key) {
    final data = _pendingUploadsBox.get(key);
    if (data == null) return [];
    try {
      return jsonDecode(data);
    } catch (e) {
      return [];
    }
  }

  /// Check if there are pending uploads
  bool hasPendingUploads() {
    return _pendingUploadsBox.isNotEmpty;
  }

  /// Get all pending hazard reports
  List<Map<String, dynamic>> getPendingHazardReports() {
    return _getPendingUploads('hazard_reports').cast<Map<String, dynamic>>();
  }

  /// Clear pending hazard reports after successful upload
  Future<void> clearHazardReportsQueue() async {
    await _pendingUploadsBox.delete('hazard_reports');
  }

  /// Get pending driving sessions
  List<Map<String, dynamic>> getPendingSessions() {
    return _getPendingUploads('driving_sessions').cast<Map<String, dynamic>>();
  }

  /// Clear pending driving sessions after successful upload
  Future<void> clearSessionsQueue() async {
    await _pendingUploadsBox.delete('driving_sessions');
  }

  // ============ Maintenance ============

  /// Clear all cached data (for logout)
  Future<void> clearAllData() async {
    await _parkingBox.clear();
    await _hazardsBox.clear();
    await _routesBox.clear();
    await _complianceBox.clear();
    await _pendingUploadsBox.clear();
  }

  /// Clear only settings (for account reset)
  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }

  /// Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'parking_entries': _parkingBox.length,
      'hazard_entries': _hazardsBox.length,
      'route_entries': _routesBox.length,
      'compliance_entries': _complianceBox.length,
      'pending_uploads': _pendingUploadsBox.length,
      'settings': _settingsBox.length,
    };
  }
}
