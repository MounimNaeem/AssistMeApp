import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScheduleModel {
  final String id;
  final String title;
  final String body;
  final bool enabled;
  final String frequencyType; // 'daily', 'days', 'weekly', 'weeks', 'months', 'selected_days'
  final int frequencyValue;
  final String preferredTime; // 'HH:mm' format
  final List<String> selectedDays; // ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  final DateTime? lastSentAt;
  final DateTime? nextScheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationScheduleModel({
    required this.id,
    required this.title,
    required this.body,
    required this.enabled,
    required this.frequencyType,
    required this.frequencyValue,
    required this.preferredTime,
    this.selectedDays = const [],
    this.lastSentAt,
    this.nextScheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationScheduleModel.fromJson(Map<String, dynamic> json) {
    return NotificationScheduleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      enabled: json['enabled'] as bool? ?? true,
      frequencyType: json['frequencyType'] as String,
      frequencyValue: json['frequencyValue'] as int,
      preferredTime: json['preferredTime'] as String,
      selectedDays: json['selectedDays'] != null
          ? List<String>.from(json['selectedDays'] as List)
          : [],
      lastSentAt: json['lastSentAt'] != null
          ? (json['lastSentAt'] as Timestamp).toDate()
          : null,
      nextScheduledAt: json['nextScheduledAt'] != null
          ? (json['nextScheduledAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'enabled': enabled,
      'frequencyType': frequencyType,
      'frequencyValue': frequencyValue,
      'preferredTime': preferredTime,
      'selectedDays': selectedDays,
      'lastSentAt': lastSentAt != null ? Timestamp.fromDate(lastSentAt!) : null,
      'nextScheduledAt':
          nextScheduledAt != null ? Timestamp.fromDate(nextScheduledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NotificationScheduleModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? enabled,
    String? frequencyType,
    int? frequencyValue,
    String? preferredTime,
    List<String>? selectedDays,
    DateTime? lastSentAt,
    DateTime? nextScheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      enabled: enabled ?? this.enabled,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyValue: frequencyValue ?? this.frequencyValue,
      preferredTime: preferredTime ?? this.preferredTime,
      selectedDays: selectedDays ?? this.selectedDays,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      nextScheduledAt: nextScheduledAt ?? this.nextScheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Default weight reminder schedule
  static NotificationScheduleModel defaultWeightReminder() {
    final now = DateTime.now();
    return NotificationScheduleModel(
      id: 'weight_reminder',
      title: 'Time to log your weight! \u2696\ufe0f',
      body: 'Track your progress by adding today\'s weight',
      enabled: true,
      frequencyType: 'days',
      frequencyValue: 3,
      preferredTime: '09:00',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create a new empty notification with generated unique ID
  static NotificationScheduleModel createNew() {
    final now = DateTime.now();
    final uniqueId = 'notification_${now.millisecondsSinceEpoch}';
    return NotificationScheduleModel(
      id: uniqueId,
      title: '',
      body: '',
      enabled: true,
      frequencyType: 'daily',
      frequencyValue: 1,
      preferredTime: '09:00',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Display name for the notification
  String get displayName {
    if (id == 'weight_reminder') return 'Weight Reminder';
    if (id == 'bmi_reminder') return 'BMI Reminder';
    if (id == 'exercise_reminder') return 'Exercise Reminder';
    // For custom notifications, use the title (first few words)
    if (title.isEmpty) return 'New Reminder';
    final words = title.split(' ').take(3).join(' ');
    return words.length > 20 ? '${words.substring(0, 17)}...' : words;
  }

  String get frequencyDisplay {
    final unit = frequencyValue == 1
        ? frequencyType.substring(0, frequencyType.length - 1)
        : frequencyType;
    return 'Every $frequencyValue $unit';
  }
}
