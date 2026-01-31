/// Exercise categories
enum ExerciseCategory {
  abs('Abs'),
  back('Back'),
  biceps('Biceps'),
  cardio('Cardio'),
  chest('Chest'),
  legs('Legs'),
  shoulders('Shoulders'),
  triceps('Triceps');

  final String displayName;
  const ExerciseCategory(this.displayName);
}

/// Exercise types with their tracking parameters
enum ExerciseType {
  strengthWeightReps('Strength: Weight, Reps', 'Bench Press, Dumbbell Row, Cable Crossovers'),
  strengthWeightTime('Strength: Weight, Time', 'Weighted Static Holds'),
  bodyweightWeightReps('Bodyweight: Weight, Reps', 'Dips, Pull Up, Chin Up'),
  bodyweightReps('Bodyweight: Reps', 'Push Ups, Bodyweight Squat'),
  bodyweightTime('Bodyweight: Time', 'Front Plank, Wall Sits'),
  assistedBodyweight('Assisted bodyweight: Weight, Reps', 'Assisted Dips, Assisted Chin Up'),
  cardio('Cardio: Time, Distance, Kcal', 'Running, Stationary Bike'),
  other('Other: Notes', 'Stretching');

  final String displayName;
  final String examples;
  const ExerciseType(this.displayName, this.examples);
}

/// Single leg/arm option
enum SingleLimbOption {
  no('Default(No)'),
  singleLeg('Single Leg'),
  singleArm('Single Arm');

  final String displayName;
  const SingleLimbOption(this.displayName);
}

class ExerciseTemplateModel {
  final String exerciseName;
  final int plannedSets;
  final int warmUpSets;
  final String? category;
  final String? exerciseType;
  final String? singleLimbOption;
  final String notes;

  ExerciseTemplateModel({
    required this.exerciseName,
    required this.plannedSets,
    this.warmUpSets = 0,
    this.category,
    this.exerciseType,
    this.singleLimbOption,
    this.notes = '',
  });

  factory ExerciseTemplateModel.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplateModel(
      exerciseName: json['exerciseName'] as String,
      plannedSets: json['plannedSets'] as int,
      warmUpSets: json['warmUpSets'] as int? ?? 0,
      category: json['category'] as String?,
      exerciseType: json['exerciseType'] as String?,
      singleLimbOption: json['singleLimbOption'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'plannedSets': plannedSets,
      'warmUpSets': warmUpSets,
      'category': category,
      'exerciseType': exerciseType,
      'singleLimbOption': singleLimbOption,
      'notes': notes,
    };
  }

  ExerciseTemplateModel copyWith({
    String? exerciseName,
    int? plannedSets,
    int? warmUpSets,
    String? category,
    String? exerciseType,
    String? singleLimbOption,
    String? notes,
  }) {
    return ExerciseTemplateModel(
      exerciseName: exerciseName ?? this.exerciseName,
      plannedSets: plannedSets ?? this.plannedSets,
      warmUpSets: warmUpSets ?? this.warmUpSets,
      category: category ?? this.category,
      exerciseType: exerciseType ?? this.exerciseType,
      singleLimbOption: singleLimbOption ?? this.singleLimbOption,
      notes: notes ?? this.notes,
    );
  }
}
