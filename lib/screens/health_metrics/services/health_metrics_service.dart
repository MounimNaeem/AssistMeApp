import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_metrics_model.dart';

class HealthMetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'health_metrics';

  /// Returns a real-time stream of all health metrics (shared across all users)
  Stream<List<HealthMetricsModel>> getHealthMetricsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthMetricsModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addHealthMetrics(HealthMetricsModel metrics) async {
    try {
      await _firestore.collection(_collection).doc(metrics.id).set(metrics.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHealthMetrics(String metricsId, HealthMetricsModel metrics) async {
    try {
      await _firestore.collection(_collection).doc(metricsId).update(metrics.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHealthMetrics(String metricsId) async {
    try {
      await _firestore.collection(_collection).doc(metricsId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
