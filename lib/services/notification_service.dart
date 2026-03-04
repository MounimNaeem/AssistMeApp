import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles FCM notifications in all app states: foreground, background, and killed
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service - call once in main.dart
  Future<void> init() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications for foreground display
    await _initLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification (killed state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Handle foreground messages - display as local notification
  void _handleForegroundMessage(RemoteMessage message) {
    print('======================================');
    print('Foreground message received!');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    print('Message ID: ${message.messageId}');
    print('======================================');

    final notification = message.notification;
    if (notification == null) {
      print('Warning: Notification is null, only data payload received');
      return;
    }

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap when app is in background/killed
  void _handleNotificationTap(RemoteMessage message) {
    print('======================================');
    print('Notification tapped!');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    print('======================================');
    // TODO: Navigate to specific screen based on message.data
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on payload
  }

  /// Get FCM token and save to Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      // On iOS, ensure APNS token is available before getting FCM token
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();

        // Retry up to 5 times with increasing delays
        int retryCount = 0;
        while (apnsToken == null && retryCount < 5) {
          print('APNS token not available yet, waiting... (attempt ${retryCount + 1}/5)');
          await Future.delayed(Duration(seconds: 1 + retryCount));
          apnsToken = await _messaging.getAPNSToken();
          retryCount++;
        }

        if (apnsToken == null) {
          print('APNS token still not available after $retryCount attempts. Cannot retrieve FCM token.');
          // Use token refresh listener as fallback
          _setupTokenRefreshListener(userId);
          return;
        } else {
          print('APNS token retrieved: $apnsToken');
        }
      }

      final token = await _messaging.getToken();
      if (token == null) {
        print('FCM token is null, will retry on token refresh');
        _setupTokenRefreshListener(userId);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });

      print('FCM token saved for user: $userId and token is $token');

      // Listen for token refresh
      _setupTokenRefreshListener(userId);
    } catch (e) {
      print('Error saving FCM token: $e');
      // Setup listener as fallback
      _setupTokenRefreshListener(userId);
    }
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener(String userId) {
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });
      print('FCM token refreshed and saved for user: $userId');
    });
  }

  /// Clear FCM token from Firestore (call on logout)
  Future<void> clearTokenFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': null,
      });
      print('FCM token cleared for user: $userId');
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('======================================');
  print('Background message received!');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  print('Message ID: ${message.messageId}');
  print('======================================');
  // Background messages are automatically displayed by FCM
  // No need to show local notification here
}
