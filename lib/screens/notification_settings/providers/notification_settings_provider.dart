import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_schedule_model.dart';
import '../services/notification_settings_service.dart';

final notificationSettingsProvider =
    ChangeNotifierProvider((ref) => NotificationSettingsProvider());

class NotificationSettingsProvider extends ChangeNotifier {
  final NotificationSettingsService _service = NotificationSettingsService();

  List<NotificationScheduleModel> _schedules = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<NotificationScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotificationScheduleModel? getScheduleById(String id) {
    try {
      return _schedules.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void startListening() {
    _isLoading = true;
    notifyListeners();

    // Initialize default schedules
    _service.initializeDefaultSchedules();

    _subscription?.cancel();
    _subscription = _service.getSchedulesStream().listen(
      (schedules) {
        _schedules = schedules;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> saveSchedule(NotificationScheduleModel schedule) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.saveSchedule(schedule);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    try {
      await _service.toggleSchedule(id, enabled);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _service.deleteSchedule(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
