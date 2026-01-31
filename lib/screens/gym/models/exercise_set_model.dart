class ExerciseSetModel {
  final int setNumber;
  final double weight;
  final String weightUnit;
  final int reps;
  final String notes;

  ExerciseSetModel({
    required this.setNumber,
    required this.weight,
    required this.weightUnit,
    required this.reps,
    required this.notes,
  });

  factory ExerciseSetModel.fromJson(Map<String, dynamic> json) {
    return ExerciseSetModel(
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weightUnit'] as String,
      reps: json['reps'] as int,
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'weightUnit': weightUnit,
      'reps': reps,
      'notes': notes,
    };
  }

  ExerciseSetModel copyWith({
    int? setNumber,
    double? weight,
    String? weightUnit,
    int? reps,
    String? notes,
  }) {
    return ExerciseSetModel(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      reps: reps ?? this.reps,
      notes: notes ?? this.notes,
    );
  }
}
