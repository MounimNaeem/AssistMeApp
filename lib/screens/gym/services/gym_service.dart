import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_routine_model.dart';
import '../models/gym_workout_model.dart';

class GymService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _routinesCollection = 'gym_routines';
  final String _workoutsCollection = 'gym_workouts';

  // ==================== ROUTINES ====================

  /// Returns a real-time stream of all routines (shared across all users)
  Stream<List<GymRoutineModel>> getRoutinesStream() {
    return _firestore
        .collection(_routinesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymRoutineModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Add a new routine
  Future<void> addRoutine(GymRoutineModel routine) async {
    try {
      await _firestore.collection(_routinesCollection).doc(routine.id).set(routine.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing routine
  Future<void> updateRoutine(GymRoutineModel routine) async {
    try {
      await _firestore.collection(_routinesCollection).doc(routine.id).update(routine.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a routine
  Future<void> deleteRoutine(String routineId) async {
    try {
      await _firestore.collection(_routinesCollection).doc(routineId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== WORKOUTS ====================

  /// Returns a real-time stream of all workouts (shared across all users)
  Stream<List<GymWorkoutModel>> getWorkoutsStream() {
    return _firestore
        .collection(_workoutsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymWorkoutModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Save (create or update) a workout
  Future<void> saveWorkout(GymWorkoutModel workout) async {
    try {
      await _firestore.collection(_workoutsCollection).doc(workout.id).set(workout.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _firestore.collection(_workoutsCollection).doc(workoutId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
