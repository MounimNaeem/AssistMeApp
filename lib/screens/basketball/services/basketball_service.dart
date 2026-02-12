import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/basketball_drill_model.dart';

class BasketballService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'basketball_drills';

  /// Returns a real-time stream of all basketball drills (shared across all users)
  Stream<List<BasketballDrillModel>> getDrillsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BasketballDrillModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get drills for a specific category
  Stream<List<BasketballDrillModel>> getDrillsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BasketballDrillModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addDrill(BasketballDrillModel drill) async {
    await _firestore.collection(_collection).doc(drill.id).set(drill.toJson());
  }

  Future<void> updateDrill(String drillId, BasketballDrillModel drill) async {
    await _firestore.collection(_collection).doc(drillId).update(drill.toJson());
  }

  Future<void> deleteDrill(String drillId) async {
    await _firestore.collection(_collection).doc(drillId).delete();
  }
}
