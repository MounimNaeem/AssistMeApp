import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_routine_model.dart';
import '../models/gym_workout_model.dart';
import '../models/workout_exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../services/gym_service.dart';

final gymProvider = ChangeNotifierProvider((ref) => GymProvider());

class GymProvider extends ChangeNotifier {
  final GymService _gymService = GymService();
  StreamSubscription<List<GymRoutineModel>>? _routinesSubscription;
  StreamSubscription<List<GymWorkoutModel>>? _workoutsSubscription;

  bool isLoading = false;
  String? errorMessage;
  List<GymRoutineModel> routines = [];
  List<GymWorkoutModel> workoutHistory = [];

  // ==================== LISTENERS ====================

  /// Starts listening to real-time routines (shared across all users)
  void startListeningToRoutines() {
    if (_routinesSubscription != null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _routinesSubscription = _gymService.getRoutinesStream().listen(
      (routinesList) {
        routines = routinesList;
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

  /// Starts listening to real-time workouts (shared across all users)
  void startListeningToWorkouts() {
    if (_workoutsSubscription != null) return;

    _workoutsSubscription = _gymService.getWorkoutsStream().listen(
      (workouts) {
        workoutHistory = workouts;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// Stops all listeners
  void stopListening() {
    _routinesSubscription?.cancel();
    _routinesSubscription = null;
    _workoutsSubscription?.cancel();
    _workoutsSubscription = null;
  }

  // ==================== ROUTINE OPERATIONS ====================

  /// Add a new routine
  Future<void> addRoutine(GymRoutineModel routine) async {
    try {
      isLoading = true;
      notifyListeners();
      await _gymService.addRoutine(routine);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing routine
  Future<void> updateRoutine(GymRoutineModel routine) async {
    try {
      isLoading = true;
      notifyListeners();
      await _gymService.updateRoutine(routine);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a routine
  Future<void> deleteRoutine(String routineId) async {
    try {
      isLoading = true;
      notifyListeners();
      await _gymService.deleteRoutine(routineId);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get a routine by ID
  GymRoutineModel? getRoutineById(String routineId) {
    try {
      return routines.firstWhere((r) => r.id == routineId);
    } catch (_) {
      return null;
    }
  }

  // ==================== WORKOUT OPERATIONS ====================

  /// Save (create or update) a workout
  Future<void> saveWorkout(GymWorkoutModel workout) async {
    try {
      isLoading = true;
      notifyListeners();
      await _gymService.saveWorkout(workout);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      isLoading = true;
      notifyListeners();
      await _gymService.deleteWorkout(workoutId);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new workout from a routine template and save it immediately
  Future<GymWorkoutModel> startWorkoutFromRoutine(
    GymRoutineModel routine,
    String userId,
  ) async {
    final now = DateTime.now();
    final workout = GymWorkoutModel(
      id: const Uuid().v4(),
      userId: userId,
      routineId: routine.id,
      routineName: routine.routineName,
      date: now,
      startTime: now,
      endTime: null, // Will be set when workout ends
      duration: 0,
      notes: routine.notes,
      exercises: routine.exercises.map((template) {
        return WorkoutExerciseModel(
          exerciseName: template.exerciseName,
          completed: false,
          sets: List.generate(
            template.plannedSets,
            (index) => ExerciseSetModel(
              setNumber: index + 1,
              weight: 0,
              weightUnit: 'kg',
              reps: 0,
              notes: '',
            ),
          ),
        );
      }).toList(),
      completedAt: null,
      isCompleted: false,
    );

    // Save immediately to database
    await saveWorkout(workout);
    return workout;
  }

  /// Get incomplete workout for a routine (if user started but didn't finish)
  GymWorkoutModel? getIncompleteWorkoutForRoutine(String routineId) {
    try {
      return workoutHistory.firstWhere(
        (w) => w.routineId == routineId && !w.isCompleted,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all completed workouts (for Log tab)
  List<GymWorkoutModel> get completedWorkouts {
    return workoutHistory.where((w) => w.isCompleted).toList();
  }

  /// Get workout by ID
  GymWorkoutModel? getWorkoutById(String workoutId) {
    try {
      return workoutHistory.firstWhere((w) => w.id == workoutId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
