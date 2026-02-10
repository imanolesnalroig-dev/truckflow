import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/push_notification_service.dart';

/// Provider for push notification service
final pushNotificationProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// Provider to track if push notifications are enabled
final pushNotificationsEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for foreground notification messages
final foregroundMessageProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessage;
});

/// Provider for notification opened from background
final messageOpenedAppProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessageOpenedApp;
});
