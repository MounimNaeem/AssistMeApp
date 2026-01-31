import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_log_model.dart';
import '../services/food_service.dart';

final foodProvider = ChangeNotifierProvider((ref) => FoodProvider());

class FoodProvider extends ChangeNotifier {
  final FoodService _foodService = FoodService();
  StreamSubscription<List<FoodLogModel>>? _subscription;

  bool isLoading = false;
  String? errorMessage;
  Map<String, List<FoodLogModel>> foodLogsByDate = {};

  /// Starts listening to real-time food logs (shared across all users)
  void startListening() {
    if (_subscription != null) return; // Already listening

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _subscription = _foodService.getFoodLogsStream().listen(
      (logs) {
        // Group by date
        foodLogsByDate = {};
        for (var log in logs) {
          if (!foodLogsByDate.containsKey(log.date)) {
            foodLogsByDate[log.date] = [];
          }
          foodLogsByDate[log.date]!.add(log);
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

  Future<void> addFoodLog(FoodLogModel foodLog) async {
    try {
      await _foodService.addFoodLog(foodLog);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateFoodLog(String logId, FoodLogModel foodLog) async {
    try {
      await _foodService.updateFoodLog(logId, foodLog);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteFoodLog(String logId) async {
    try {
      await _foodService.deleteFoodLog(logId);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  int getTotalCaloriesForDate(String date) {
    if (!foodLogsByDate.containsKey(date)) return 0;
    return foodLogsByDate[date]!.fold(0, (sum, item) => sum + item.calories);
  }

  int getTotalProteinForDate(String date) {
    if (!foodLogsByDate.containsKey(date)) return 0;
    return foodLogsByDate[date]!.fold(0, (sum, item) => sum + (item.protein ?? 0));
  }

  int getTotalCarbsForDate(String date) {
    if (!foodLogsByDate.containsKey(date)) return 0;
    return foodLogsByDate[date]!.fold(0, (sum, item) => sum + (item.carbs ?? 0));
  }

  int getTotalFatForDate(String date) {
    if (!foodLogsByDate.containsKey(date)) return 0;
    return foodLogsByDate[date]!.fold(0, (sum, item) => sum + (item.fat ?? 0));
  }

  /// Get average macros for the last 3 days with food logs
  /// Returns a map with 'protein', 'carbs', 'fat' keys
  Map<String, int> getAverageMacrosLast3Days() {
    if (foodLogsByDate.isEmpty) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    // Sort dates descending and take up to 3
    final sortedDates = foodLogsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final recentDates = sortedDates.take(3).toList();

    if (recentDates.isEmpty) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    for (final date in recentDates) {
      totalProtein += getTotalProteinForDate(date);
      totalCarbs += getTotalCarbsForDate(date);
      totalFat += getTotalFatForDate(date);
    }

    final dayCount = recentDates.length;
    return {
      'protein': (totalProtein / dayCount).round(),
      'carbs': (totalCarbs / dayCount).round(),
      'fat': (totalFat / dayCount).round(),
    };
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
