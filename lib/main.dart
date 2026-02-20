import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:home_widget/home_widget.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';

/// Callback for widget interactions
@pragma("vm:entry-point")
void backgroundCallback(Uri? uri) async {
  // Handle widget tap callbacks
  if (uri != null) {
    print('Widget callback received: $uri');
    // You can handle specific routes here
    // For example: navigate to calendar, fitness, etc.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set App Group ID for iOS widget data sharing
  HomeWidget.setAppGroupId('group.com.mounim.assitme');

  // Register widget interaction callback
  HomeWidget.registerInteractivityCallback(backgroundCallback);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().init();

  await LocalStorageService.init();

  runApp(const ProviderScope(child: MyApp()));
}
