import 'exercise_set_model.dart';

class WorkoutExerciseModel {
  final String exerciseName;
  final bool completed;
  final List<ExerciseSetModel> sets;

  WorkoutExerciseModel({
    required this.exerciseName,
    required this.completed,
    required this.sets,
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      exerciseName: json['exerciseName'] as String,
      completed: json['completed'] as bool,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => ExerciseSetModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'completed': completed,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  WorkoutExerciseModel copyWith({
    String? exerciseName,
    bool? completed,
    List<ExerciseSetModel>? sets,
  }) {
    return WorkoutExerciseModel(
      exerciseName: exerciseName ?? this.exerciseName,
      completed: completed ?? this.completed,
      sets: sets ?? this.sets,
    );
  }
}
