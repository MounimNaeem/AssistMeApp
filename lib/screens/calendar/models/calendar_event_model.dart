import 'package:cloud_firestore/cloud_firestore.dart';

/// Predefined event colors for categorization
class EventColors {
  static const int red = 0xFFF44336;
  static const int green = 0xFF4CAF50;
  static const int blue = 0xFF2196F3;
  static const int purple = 0xFF9C27B0;
  static const int orange = 0xFFFF9800;
  static const int teal = 0xFF009688;
  static const int pink = 0xFFE91E63;
  static const int indigo = 0xFF3F51B5;

  static List<int> get all => [red, green, blue, purple, orange, teal, pink, indigo];

  static List<String> get names => ['Red', 'Green', 'Blue', 'Purple', 'Orange', 'Teal', 'Pink', 'Indigo'];
}

class CalendarEventModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime eventDateTime;
  final DateTime? endDateTime;
  final int eventColor;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final DateTime? reminderAt;
  final bool reminderSent;
  final DateTime createdAt;

  CalendarEventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.eventDateTime,
    this.endDateTime,
    this.eventColor = EventColors.blue,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 30,
    this.reminderAt,
    this.reminderSent = false,
    required this.createdAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return CalendarEventModel(
      id: safeString(json['id']),
      userId: safeString(json['userId']),
      title: safeString(json['title']),
      description: safeString(json['description']),
      eventDateTime: (json['eventDateTime'] as Timestamp).toDate(),
      endDateTime: parseTimestamp(json['endDateTime']),
      eventColor: json['eventColor'] ?? EventColors.blue,
      reminderEnabled: json['reminderEnabled'] == true,
      reminderMinutesBefore: json['reminderMinutesBefore'] ?? 30,
      reminderAt: parseTimestamp(json['reminderAt']),
      reminderSent: json['reminderSent'] == true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'endDateTime': endDateTime != null ? Timestamp.fromDate(endDateTime!) : null,
      'eventColor': eventColor,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'reminderSent': reminderSent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CalendarEventModel copyWith({
    String? title,
    String? description,
    DateTime? eventDateTime,
    DateTime? endDateTime,
    int? eventColor,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    DateTime? reminderAt,
    bool? reminderSent,
  }) {
    return CalendarEventModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      eventColor: eventColor ?? this.eventColor,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderSent: reminderSent ?? this.reminderSent,
      createdAt: createdAt,
    );
  }

  /// Calculate the reminder time based on event time and minutes before
  DateTime? calculateReminderAt() {
    if (!reminderEnabled) return null;
    return eventDateTime.subtract(Duration(minutes: reminderMinutesBefore));
  }
}
