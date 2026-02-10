import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_storage_service.dart';

/// Global offline storage service provider
/// Must be overridden in main.dart with the initialized instance
final offlineStorageProvider = Provider<OfflineStorageService>((ref) {
  throw UnimplementedError('OfflineStorageService must be initialized in main()');
});

/// Provider to track offline mode status
final isOfflineModeProvider = StateProvider<bool>((ref) => false);

/// Provider to track pending uploads count
final pendingUploadsCountProvider = Provider<int>((ref) {
  final storage = ref.watch(offlineStorageProvider);
  final stats = storage.getStorageStats();
  return stats['pending_uploads'] ?? 0;
});
