import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_template_model.dart';

/// Routine target options
enum RoutineTarget {
  latest('Latest'),
  strength('Strength'),
  hypertrophy('Hypertrophy'),
  endurance('Endurance'),
  custom('Custom');

  final String displayName;
  const RoutineTarget(this.displayName);
}

class GymRoutineModel {
  final String id;
  final String routineName;
  final String target;
  final String notes;
  final String createdBy;
  final List<ExerciseTemplateModel> exercises;
  final DateTime createdAt;

  GymRoutineModel({
    required this.id,
    required this.routineName,
    this.target = 'Latest',
    this.notes = '',
    required this.createdBy,
    required this.exercises,
    required this.createdAt,
  });

  factory GymRoutineModel.fromJson(Map<String, dynamic> json) {
    return GymRoutineModel(
      id: json['id'] as String,
      routineName: json['routineName'] as String,
      target: json['target'] as String? ?? 'Latest',
      notes: json['notes'] as String? ?? '',
      createdBy: json['createdBy'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseTemplateModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineName': routineName,
      'target': target,
      'notes': notes,
      'createdBy': createdBy,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GymRoutineModel copyWith({
    String? id,
    String? routineName,
    String? target,
    String? notes,
    String? createdBy,
    List<ExerciseTemplateModel>? exercises,
    DateTime? createdAt,
  }) {
    return GymRoutineModel(
      id: id ?? this.id,
      routineName: routineName ?? this.routineName,
      target: target ?? this.target,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
