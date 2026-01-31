import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/home_service.dart';
import '../../auth/models/user_model.dart';
import '../../food/providers/food_provider.dart';

final homeProvider = ChangeNotifierProvider((ref) => HomeProvider());

class HomeProvider extends ChangeNotifier {
  final HomeService _homeService = HomeService();

  bool isLoading = false;
  String? errorMessage;
  UserModel? userProfile;

  Future<void> refreshUserProfile(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      userProfile = await _homeService.getUserProfile(userId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the average calories for the last 3 days that have food logs.
  /// For example, if logs exist for Jan 17, Jan 14, Jan 13 (no logs on 15, 16),
  /// it will return the average of those 3 days.
  int getAverageCaloriesLast3Days(FoodProvider foodProviderState) {
    final foodLogsByDate = foodProviderState.foodLogsByDate;

    if (foodLogsByDate.isEmpty) return 0;

    // Get all dates with logs and sort them in descending order (most recent first)
    final sortedDates = foodLogsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Take up to 3 most recent days with logs
    final last3Days = sortedDates.take(3).toList();

    if (last3Days.isEmpty) return 0;

    int totalCalories = 0;
    for (final date in last3Days) {
      totalCalories += foodProviderState.getTotalCaloriesForDate(date);
    }

    return (totalCalories / last3Days.length).round();
  }
}
