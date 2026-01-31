import 'package:cloud_firestore/cloud_firestore.dart';

class HealthMetricsModel {
  final String id;
  final String userId;
  final double? weight; // kg
  final double? height; // cm
  final double? bmi; // calculated
  final double? biceps; // cm
  final double? waist; // cm
  final double? bodyFat; // percentage
  final double? muscleMass; // kg
  final int? calorieGoal; // daily calorie goal
  final String date; // YYYY-MM-DD
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthMetricsModel({
    required this.id,
    required this.userId,
    this.weight,
    this.height,
    this.bmi,
    this.biceps,
    this.waist,
    this.bodyFat,
    this.muscleMass,
    this.calorieGoal,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate BMI from weight (kg) and height (cm)
  /// BMI = weight / (height in meters)^2
  static double? calculateBMI(double? weight, double? height) {
    if (weight == null || height == null || height <= 0) return null;
    final heightInMeters = height / 100;
    return double.parse((weight / (heightInMeters * heightInMeters)).toStringAsFixed(1));
  }

  factory HealthMetricsModel.fromJson(Map<String, dynamic> json) {
    return HealthMetricsModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      biceps: (json['biceps'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      bodyFat: (json['bodyFat'] as num?)?.toDouble(),
      muscleMass: (json['muscleMass'] as num?)?.toDouble(),
      calorieGoal: (json['calorieGoal'] as num?)?.toInt(),
      date: json['date'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'biceps': biceps,
      'waist': waist,
      'bodyFat': bodyFat,
      'muscleMass': muscleMass,
      'calorieGoal': calorieGoal,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HealthMetricsModel copyWith({
    String? id,
    String? userId,
    double? weight,
    double? height,
    double? bmi,
    double? biceps,
    double? waist,
    double? bodyFat,
    double? muscleMass,
    int? calorieGoal,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthMetricsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      biceps: biceps ?? this.biceps,
      waist: waist ?? this.waist,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
