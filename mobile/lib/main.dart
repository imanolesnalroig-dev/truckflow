import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/services/offline_storage_service.dart';
import 'core/providers/offline_storage_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/providers/push_notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline storage (Hive)
  final offlineStorage = OfflineStorageService();
  await offlineStorage.initialize();

  // Try to initialize Firebase (may fail if not configured)
  PushNotificationService? pushService;
  try {
    await Firebase.initializeApp();
    pushService = PushNotificationService();
    await pushService.initialize();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase not configured: $e');
    // Continue without push notifications
  }

  runApp(
    ProviderScope(
      overrides: [
        // Provide the initialized storage instance
        offlineStorageProvider.overrideWithValue(offlineStorage),
        // Provide push notification service if available
        if (pushService != null)
          pushNotificationProvider.overrideWithValue(pushService),
      ],
      child: const TruckFlowApp(),
    ),
  );
}
