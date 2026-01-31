import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = ChangeNotifierProvider((ref) => SettingsProvider());

class SettingsProvider extends ChangeNotifier {
  // Placeholder for settings logic
  bool notificationsEnabled = true;

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }
}
