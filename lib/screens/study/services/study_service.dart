import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_task_model.dart';

class StudyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'study_tasks';

  /// Returns a real-time stream of all study tasks (shared across all users)
  Stream<List<StudyTaskModel>> getTasksStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyTaskModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addTask(StudyTaskModel task) async {
    await _firestore.collection(_collection).doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(String taskId, StudyTaskModel task) async {
    await _firestore.collection(_collection).doc(taskId).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).delete();
  }
}
