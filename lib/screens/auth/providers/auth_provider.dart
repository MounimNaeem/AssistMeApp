import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/notification_service.dart';

final authProvider = ChangeNotifierProvider((ref) => AuthProvider());

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;

  void restoreUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.signIn(email, password);
      if (currentUser == null) {
        errorMessage = 'User data not found';
      } else {
        await LocalStorageService.saveLoginData(currentUser!);
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.signUp(name, email, password);
      if (currentUser != null) {
        await LocalStorageService.saveLoginData(currentUser!);
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Clear FCM token before logout
    if (currentUser != null) {
      await NotificationService().clearTokenFromFirestore(currentUser!.id);
    }
    await _authService.signOut();
    await LocalStorageService.clearLoginData();
    currentUser = null;
    notifyListeners();
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.updatePassword(currentPassword, newPassword);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
