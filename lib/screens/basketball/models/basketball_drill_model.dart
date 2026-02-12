import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories for basketball drills
class DrillCategory {
  static const String finishing = 'finishing';
  static const String shooting = 'shooting';
  static const String handles = 'handles';
  static const String conditioning = 'conditioning';

  static List<String> get all => [finishing, shooting, handles, conditioning];

  static String getDisplayName(String category) {
    switch (category) {
      case finishing:
        return 'Finishing';
      case shooting:
        return 'Shooting';
      case handles:
        return 'Handles';
      case conditioning:
        return 'Conditioning';
      default:
        return category;
    }
  }
}

class BasketballDrillModel {
  final String id;
  final String userId;
  final String createdBy;
  final String category;
  final String drillName;
  final String description;
  final String? videoUrl;
  final DateTime createdAt;

  BasketballDrillModel({
    required this.id,
    required this.userId,
    required this.createdBy,
    required this.category,
    required this.drillName,
    required this.description,
    this.videoUrl,
    required this.createdAt,
  });

  factory BasketballDrillModel.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return BasketballDrillModel(
      id: safeString(json['id']),
      userId: safeString(json['userId']),
      createdBy: safeString(json['createdBy']),
      category: safeString(json['category']),
      drillName: safeString(json['drillName']),
      description: safeString(json['description']),
      videoUrl: json['videoUrl'] != null ? safeString(json['videoUrl']) : null,
      createdAt: parseTimestamp(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdBy': createdBy,
      'category': category,
      'drillName': drillName,
      'description': description,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BasketballDrillModel copyWith({
    String? category,
    String? drillName,
    String? description,
    String? videoUrl,
  }) {
    return BasketballDrillModel(
      id: id,
      userId: userId,
      createdBy: createdBy,
      category: category ?? this.category,
      drillName: drillName ?? this.drillName,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt,
    );
  }
}
