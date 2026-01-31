import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudyTaskModel {
  final String id;
  final String userId;
  final String taskName;
  final String detailsJson; // Stores Quill Delta JSON
  final String detailsPlainText; // Stores plain text for display
  final bool completed;
  final String date;
  final DateTime createdAt;

  StudyTaskModel({
    required this.id,
    required this.userId,
    required this.taskName,
    this.detailsJson = '',
    this.detailsPlainText = '',
    required this.completed,
    required this.date,
    required this.createdAt,
  });

  bool get hasDetails => detailsPlainText.trim().isNotEmpty;

  factory StudyTaskModel.fromJson(Map<String, dynamic> json) {
    // Safe string extraction helper
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    // Handle backward compatibility with old 'details' field
    String detailsJson = safeString(json['detailsJson']);
    String detailsPlainText = safeString(json['detailsPlainText']);

    // If no new fields, try old 'details' field
    if (detailsPlainText.isEmpty && json['details'] != null) {
      detailsPlainText = safeString(json['details']);
    }

    return StudyTaskModel(
      id: safeString(json['id']),
      userId: safeString(json['userId']),
      taskName: safeString(json['taskName']),
      detailsJson: detailsJson,
      detailsPlainText: detailsPlainText,
      completed: json['completed'] == true,
      date: safeString(json['date']),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'taskName': taskName,
      'detailsJson': detailsJson,
      'detailsPlainText': detailsPlainText,
      'completed': completed,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  List<dynamic>? get detailsDelta {
    if (detailsJson.isEmpty) return null;
    try {
      return jsonDecode(detailsJson) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  StudyTaskModel copyWith({
    String? taskName,
    String? detailsJson,
    String? detailsPlainText,
    bool? completed,
    String? date,
  }) {
    return StudyTaskModel(
      id: id,
      userId: userId,
      taskName: taskName ?? this.taskName,
      detailsJson: detailsJson ?? this.detailsJson,
      detailsPlainText: detailsPlainText ?? this.detailsPlainText,
      completed: completed ?? this.completed,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}
