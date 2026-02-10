import 'dart:async';
import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'gps_service.dart';

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final gpsService = ref.watch(gpsServiceProvider);
  return TelemetryService(apiClient, gpsService);
});

class TelemetryService {
  final ApiClient _apiClient;
  final GpsService _gpsService;

  // Queue to store GPS pings for batch upload
  final Queue<GpsPosition> _pingQueue = Queue<GpsPosition>();
  static const int _maxQueueSize = 100;
  static const int _batchUploadThreshold = 10; // Upload when we have 10+ pings

  Timer? _uploadTimer;
  StreamSubscription<GpsPosition>? _gpsSubscription;

  bool _isUploading = false;
  int _failedUploadAttempts = 0;
  static const int _maxRetries = 3;

  TelemetryService(this._apiClient, this._gpsService);

  void startCollecting() {
    // Listen to GPS position updates
    _gpsSubscription = _gpsService.positionStream.listen(_onPositionUpdate);

    // Periodic upload timer - every 30-60 seconds as per spec
    _uploadTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _uploadBatch(),
    );
  }

  void stopCollecting() {
    _gpsSubscription?.cancel();
    _uploadTimer?.cancel();

    // Final upload of remaining pings
    if (_pingQueue.isNotEmpty) {
      _uploadBatch();
    }
  }

  void _onPositionUpdate(GpsPosition position) {
    // Add to queue
    _pingQueue.add(position);

    // Prevent queue from growing too large (offline scenarios)
    while (_pingQueue.length > _maxQueueSize) {
      _pingQueue.removeFirst();
    }

    // Upload if we have enough pings
    if (_pingQueue.length >= _batchUploadThreshold && !_isUploading) {
      _uploadBatch();
    }
  }

  Future<void> _uploadBatch() async {
    if (_pingQueue.isEmpty || _isUploading) return;

    _isUploading = true;

    // Take pings from queue for upload
    final pingsToUpload = <GpsPosition>[];
    while (_pingQueue.isNotEmpty && pingsToUpload.length < _batchUploadThreshold) {
      pingsToUpload.add(_pingQueue.removeFirst());
    }

    try {
      await _apiClient.sendTelemetry({
        'pings': pingsToUpload.map((p) => p.toJson()).toList(),
        'activity_state': _gpsService.activityState,
      });

      // Success - reset retry counter
      _failedUploadAttempts = 0;
    } catch (e) {
      // Failed - put pings back in queue for retry
      _failedUploadAttempts++;

      if (_failedUploadAttempts < _maxRetries) {
        // Put pings back at the front of the queue
        for (final ping in pingsToUpload.reversed) {
          _pingQueue.addFirst(ping);
        }
      } else {
        // Too many failures - discard oldest pings to prevent memory issues
        // Keep only recent pings
        while (_pingQueue.length > _maxQueueSize ~/ 2) {
          _pingQueue.removeFirst();
        }
        _failedUploadAttempts = 0;
      }
    } finally {
      _isUploading = false;
    }
  }

  // For immediate upload (e.g., when user reports something)
  Future<void> flushNow() async {
    await _uploadBatch();
  }

  int get queuedPings => _pingQueue.length;

  void dispose() {
    stopCollecting();
    _uploadTimer?.cancel();
    _gpsSubscription?.cancel();
  }
}
