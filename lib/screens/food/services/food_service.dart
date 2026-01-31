import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_log_model.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'food_logs';

  /// Returns a real-time stream of all food logs (shared across all users)
  Stream<List<FoodLogModel>> getFoodLogsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodLogModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addFoodLog(FoodLogModel foodLog) async {
    try {
      // Use the id from the model as the document ID, or let Firestore generate one if empty/dummy
      // Ideally, let Firestore generate the ID and update the model, or use a specific ID if provided.
      // Here we assume ID is generated before calling add, or we use doc().set() if we want to control ID.
      // But prompt says "Add document", so let's use .doc(foodLog.id).set() to be safe if ID is pre-generated,
      // or .add() if ID is not set. 
      // The model has 'id' field. Let's assume we pass a new ID or use the one in model.
      
      await _firestore.collection(_collection).doc(foodLog.id).set(foodLog.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFoodLog(String logId, FoodLogModel foodLog) async {
    try {
      await _firestore.collection(_collection).doc(logId).update(foodLog.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFoodLog(String logId) async {
    try {
      await _firestore.collection(_collection).doc(logId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
