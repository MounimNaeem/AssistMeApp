import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_task_model.dart';
import '../services/study_service.dart';

class StudyProvider extends ChangeNotifier {
  final StudyService _service = StudyService();
  StreamSubscription<List<StudyTaskModel>>? _subscription;

  bool isLoading = false;
  String? errorMessage;
  Map<String, List<StudyTaskModel>> tasksByDate = {};

  /// Starts listening to real-time study tasks (shared across all users)
  void startListening() {
    if (_subscription != null) return; // Already listening

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _subscription = _service.getTasksStream().listen(
      (tasks) {
        // Group by date
        tasksByDate = {};
        for (var task in tasks) {
          if (!tasksByDate.containsKey(task.date)) {
            tasksByDate[task.date] = [];
          }
          tasksByDate[task.date]!.add(task);
        }
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stops listening to real-time updates
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> addTask(StudyTaskModel task) async {
    try {
      await _service.addTask(task);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTask(String taskId, StudyTaskModel task) async {
    try {
      await _service.updateTask(taskId, task);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _service.deleteTask(taskId);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleCompletion(StudyTaskModel task) async {
    final updated = task.copyWith(completed: !task.completed);
    await updateTask(task.id, updated);
  }

  int getCompletedCountForDate(String date) {
    if (!tasksByDate.containsKey(date)) return 0;
    return tasksByDate[date]!.where((t) => t.completed).length;
  }

  int getTotalCountForDate(String date) {
    if (!tasksByDate.containsKey(date)) return 0;
    return tasksByDate[date]!.length;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
