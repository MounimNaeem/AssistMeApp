import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../services/assistant_service.dart';

class AssistantProvider extends ChangeNotifier {
  final AssistantService _service = AssistantService();
  List<UserModel> assistants = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAssistants(String clientId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      assistants = await _service.getAssistants(clientId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAssistant(
      String name, String email, String password, String clientId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.createAssistant(name, email, password, clientId);
      await loadAssistants(clientId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAssistant(
      String assistantId, String name, String email, String clientId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.updateAssistant(assistantId, name, email);
      await loadAssistants(clientId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAssistant(String assistantId, String clientId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.deleteAssistant(assistantId);
      await loadAssistants(clientId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _service.resetAssistantPassword(email);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
