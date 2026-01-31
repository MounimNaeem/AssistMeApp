import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_exercise_model.dart';

class GymWorkoutModel {
  final String id;
  final String userId;
  final String routineId;
  final String routineName;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime; // Nullable - set when workout ends
  final int duration; // in minutes
  final String notes;
  final List<WorkoutExerciseModel> exercises;
  final DateTime? completedAt; // Nullable - set when workout is completed
  final bool isCompleted;

  GymWorkoutModel({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.routineName,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.notes,
    required this.exercises,
    this.completedAt,
    this.isCompleted = false,
  });

  factory GymWorkoutModel.fromJson(Map<String, dynamic> json) {
    return GymWorkoutModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      routineId: json['routineId'] as String,
      routineName: json['routineName'] as String,
      date: (json['date'] as Timestamp).toDate(),
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null ? (json['endTime'] as Timestamp).toDate() : null,
      duration: json['duration'] as int,
      notes: json['notes'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => WorkoutExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedAt: json['completedAt'] != null ? (json['completedAt'] as Timestamp).toDate() : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'routineId': routineId,
      'routineName': routineName,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'notes': notes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
    };
  }

  GymWorkoutModel copyWith({
    String? id,
    String? userId,
    String? routineId,
    String? routineName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return GymWorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
