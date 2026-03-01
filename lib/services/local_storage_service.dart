import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/models/user_model.dart';

class LocalStorageKeys {
  static const String isLoggedIn = 'is_logged_in';
  static const String userData = 'user_data';
  static const String isDarkMode = 'is_dark_mode';
}

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveLoginData(UserModel user) async {
    await _prefs?.setBool(LocalStorageKeys.isLoggedIn, true);
    await _prefs?.setString(
      LocalStorageKeys.userData,
      jsonEncode(user.toJson()),
    );
  }

  static Future<void> clearLoginData() async {
    await _prefs?.remove(LocalStorageKeys.isLoggedIn);
    await _prefs?.remove(LocalStorageKeys.userData);
  }

  static bool get isLoggedIn {
    return _prefs?.getBool(LocalStorageKeys.isLoggedIn) ?? false;
  }

  static UserModel? get savedUser {
    final userData = _prefs?.getString(LocalStorageKeys.userData);
    if (userData == null) return null;
    return UserModel.fromJson(jsonDecode(userData));
  }

  static Future<void> saveDarkMode(bool isDark) async {
    await _prefs?.setBool(LocalStorageKeys.isDarkMode, isDark);
  }

  static bool get isDarkMode {
    return _prefs?.getBool(LocalStorageKeys.isDarkMode) ?? false;
  }
}
