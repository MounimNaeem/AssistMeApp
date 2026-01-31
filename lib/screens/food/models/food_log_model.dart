import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogModel {
  final String id;
  final String userId;
  final String mealName;
  final int numberOfServings;
  final String mealType;
  final int calories;
  final DateTime time;
  final String servingSize;
  final String date; // YYYY-MM-DD
  final DateTime createdAt;
  final int? protein; // grams
  final int? carbs; // grams
  final int? fat; // grams

  FoodLogModel({
    required this.id,
    required this.userId,
    required this.mealName,
    required this.numberOfServings,
    required this.mealType,
    required this.calories,
    required this.time,
    required this.servingSize,
    required this.date,
    required this.createdAt,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory FoodLogModel.fromJson(Map<String, dynamic> json) {
    return FoodLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      mealName: json['mealName'] as String,
      numberOfServings: json['numberOfServings'] as int,
      mealType: json['mealType'] as String,
      calories: json['calories'] as int,
      time: (json['time'] as Timestamp).toDate(),
      servingSize: json['servingSize'] as String,
      date: json['date'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      protein: json['protein'] as int?,
      carbs: json['carbs'] as int?,
      fat: json['fat'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mealName': mealName,
      'numberOfServings': numberOfServings,
      'mealType': mealType,
      'calories': calories,
      'time': Timestamp.fromDate(time),
      'servingSize': servingSize,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  FoodLogModel copyWith({
    String? id,
    String? userId,
    String? mealName,
    int? numberOfServings,
    String? mealType,
    int? calories,
    DateTime? time,
    String? servingSize,
    String? date,
    DateTime? createdAt,
    int? protein,
    int? carbs,
    int? fat,
  }) {
    return FoodLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealName: mealName ?? this.mealName,
      numberOfServings: numberOfServings ?? this.numberOfServings,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      time: time ?? this.time,
      servingSize: servingSize ?? this.servingSize,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}
