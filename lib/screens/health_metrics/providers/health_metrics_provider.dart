import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_metrics_model.dart';
import '../services/health_metrics_service.dart';

final healthMetricsProvider = ChangeNotifierProvider((ref) => HealthMetricsProvider());

class HealthMetricsProvider extends ChangeNotifier {
  final HealthMetricsService _service = HealthMetricsService();
  StreamSubscription<List<HealthMetricsModel>>? _subscription;

  bool isLoading = false;
  String? errorMessage;
  Map<String, List<HealthMetricsModel>> metricsByDate = {};
  List<HealthMetricsModel> allMetrics = [];

  /// Starts listening to real-time health metrics (shared across all users)
  void startListening() {
    if (_subscription != null) return; // Already listening

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _subscription = _service.getHealthMetricsStream().listen(
      (metrics) {
        allMetrics = metrics;
        // Group by date
        metricsByDate = {};
        for (var metric in metrics) {
          if (!metricsByDate.containsKey(metric.date)) {
            metricsByDate[metric.date] = [];
          }
          metricsByDate[metric.date]!.add(metric);
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

  /// Get the latest metrics (most recent entry)
  HealthMetricsModel? get latestMetrics {
    if (allMetrics.isEmpty) return null;
    return allMetrics.first; // Already sorted by updatedAt descending
  }

  /// Get latest weight value
  double? get latestWeight => latestMetrics?.weight;

  /// Get latest height value
  double? get latestHeight => latestMetrics?.height;

  /// Get latest BMI value
  double? get latestBMI => latestMetrics?.bmi;

  /// Get latest biceps value
  double? get latestBiceps => latestMetrics?.biceps;

  /// Get latest waist value
  double? get latestWaist => latestMetrics?.waist;

  /// Get latest body fat value
  double? get latestBodyFat => latestMetrics?.bodyFat;

  /// Get latest muscle mass value
  double? get latestMuscleMass => latestMetrics?.muscleMass;

  Future<void> addHealthMetrics(HealthMetricsModel metrics) async {
    try {
      await _service.addHealthMetrics(metrics);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateHealthMetrics(String metricsId, HealthMetricsModel metrics) async {
    try {
      await _service.updateHealthMetrics(metricsId, metrics);
      // No need to reload - real-time listener will update automatically
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteHealthMetrics(String metricsId) async {
    try {
      await _service.deleteHealthMetrics(metricsId);
      // No need to reload - real-time listener will update automatically
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
