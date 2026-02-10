import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
  // Handle background message
}

/// Push notification types for TruckFlow
enum NotificationType {
  hazardNearby,
  breakReminder,
  restRequired,
  parkingAvailable,
  routeUpdate,
  general,
}

/// Push notification service for FCM integration
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient? _apiClient;

  String? _fcmToken;
  bool _isInitialized = false;

  /// Callbacks for handling notifications
  void Function(RemoteMessage)? onForegroundMessage;
  void Function(RemoteMessage)? onBackgroundMessageOpened;
  void Function(RemoteMessage)? onInitialMessage;

  PushNotificationService({ApiClient? apiClient}) : _apiClient = apiClient;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize Firebase if not already done
      await Firebase.initializeApp();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // For driving time warnings
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_handleTokenRefresh);

        // Set up foreground message handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Set up background message tap handler
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check for initial message (app opened from notification)
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleInitialMessage(initialMessage);
        }

        // Subscribe to relevant topics
        await subscribeToTopics();

        _isInitialized = true;
        return true;
      } else {
        debugPrint('Notification permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
      return false;
    }
  }

  /// Subscribe to notification topics
  Future<void> subscribeToTopics() async {
    try {
      // Subscribe to general announcements
      await _messaging.subscribeToTopic('all_drivers');

      // Subscribe to European region hazards
      await _messaging.subscribeToTopic('hazards_eu');

      // Subscribe to compliance reminders
      await _messaging.subscribeToTopic('compliance_reminders');

      debugPrint('Subscribed to notification topics');
    } catch (e) {
      debugPrint('Failed to subscribe to topics: $e');
    }
  }

  /// Subscribe to country-specific hazards
  Future<void> subscribeToCountry(String countryCode) async {
    try {
      await _messaging.subscribeToTopic('hazards_${countryCode.toLowerCase()}');
      debugPrint('Subscribed to hazards_$countryCode');
    } catch (e) {
      debugPrint('Failed to subscribe to country hazards: $e');
    }
  }

  /// Unsubscribe from country-specific hazards
  Future<void> unsubscribeFromCountry(String countryCode) async {
    try {
      await _messaging.unsubscribeFromTopic('hazards_${countryCode.toLowerCase()}');
    } catch (e) {
      debugPrint('Failed to unsubscribe from country hazards: $e');
    }
  }

  /// Register device token with backend
  Future<void> registerDeviceWithBackend() async {
    if (_fcmToken == null || _apiClient == null) return;

    try {
      await _apiClient!.post('/api/devices/register', {
        'fcmToken': _fcmToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      debugPrint('Device registered with backend');
    } catch (e) {
      debugPrint('Failed to register device with backend: $e');
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    debugPrint('FCM Token refreshed: $token');
    _fcmToken = token;
    registerDeviceWithBackend();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    // Parse notification type
    final type = _parseNotificationType(message.data['type']);

    // Call the foreground handler if set
    onForegroundMessage?.call(message);

    // Show local notification for certain types
    if (type == NotificationType.hazardNearby ||
        type == NotificationType.restRequired) {
      _showLocalNotification(message);
    }
  }

  /// Handle message opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.notification?.title}');
    onBackgroundMessageOpened?.call(message);
  }

  /// Handle initial message when app was terminated
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('Initial message: ${message.notification?.title}');
    onInitialMessage?.call(message);
  }

  /// Parse notification type from data
  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'hazard_nearby':
        return NotificationType.hazardNearby;
      case 'break_reminder':
        return NotificationType.breakReminder;
      case 'rest_required':
        return NotificationType.restRequired;
      case 'parking_available':
        return NotificationType.parkingAvailable;
      case 'route_update':
        return NotificationType.routeUpdate;
      default:
        return NotificationType.general;
    }
  }

  /// Show a local notification (for foreground messages)
  void _showLocalNotification(RemoteMessage message) {
    // This would use flutter_local_notifications in a full implementation
    // For now, we rely on the foreground message handler callback
    debugPrint('Would show local notification: ${message.notification?.title}');
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    if (_apiClient == null || _fcmToken == null) return;

    try {
      await _apiClient!.post('/api/notifications/test', {
        'fcmToken': _fcmToken,
        'title': 'TruckFlow Test',
        'body': 'Push notifications are working!',
      });
    } catch (e) {
      debugPrint('Failed to send test notification: $e');
    }
  }

  /// Parse notification data to extract hazard info
  Map<String, dynamic>? parseHazardData(RemoteMessage message) {
    final hazardJson = message.data['hazard'];
    if (hazardJson == null) return null;

    try {
      return jsonDecode(hazardJson);
    } catch (e) {
      return null;
    }
  }

  /// Parse notification data to extract compliance warning
  Map<String, dynamic>? parseComplianceData(RemoteMessage message) {
    final complianceJson = message.data['compliance'];
    if (complianceJson == null) return null;

    try {
      return jsonDecode(complianceJson);
    } catch (e) {
      return null;
    }
  }
}
