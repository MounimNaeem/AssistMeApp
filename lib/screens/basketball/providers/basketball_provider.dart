import 'dart:async';
import 'package:flutter/material.dart';
import '../models/basketball_drill_model.dart';
import '../services/basketball_service.dart';

class BasketballProvider extends ChangeNotifier {
  final BasketballService _service = BasketballService();
  StreamSubscription<List<BasketballDrillModel>>? _subscription;

  bool isLoading = false;
  String? errorMessage;
  List<BasketballDrillModel> allDrills = [];

  /// Get drills for a specific category
  List<BasketballDrillModel> getDrillsByCategory(String category) {
    return allDrills
        .where((drill) => drill.category == category)
        .toList();
  }

  /// Get count of drills for a specific category
  int getDrillCountByCategory(String category) {
    return allDrills.where((drill) => drill.category == category).length;
  }

  /// Starts listening to real-time basketball drills (shared across all users)
  void startListening() {
    if (_subscription != null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _subscription = _service.getDrillsStream().listen(
      (drillsList) {
        allDrills = drillsList;
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

  Future<void> addDrill(BasketballDrillModel drill) async {
    try {
      await _service.addDrill(drill);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDrill(String drillId, BasketballDrillModel drill) async {
    try {
      await _service.updateDrill(drillId, drill);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDrill(String drillId) async {
    try {
      await _service.deleteDrill(drillId);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
