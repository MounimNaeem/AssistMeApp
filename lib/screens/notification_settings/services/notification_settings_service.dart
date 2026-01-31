import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_schedule_model.dart';

class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Global notification settings collection
  CollectionReference get _schedulesCollection =>
      _firestore.collection('notification_schedules');

  // Get all notification schedules
  Stream<List<NotificationScheduleModel>> getSchedulesStream() {
    return _schedulesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationScheduleModel.fromJson(
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // Get a specific schedule by ID
  Future<NotificationScheduleModel?> getSchedule(String id) async {
    final doc = await _schedulesCollection.doc(id).get();
    if (!doc.exists) return null;
    return NotificationScheduleModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Create or update a schedule
  Future<void> saveSchedule(NotificationScheduleModel schedule) async {
    await _schedulesCollection.doc(schedule.id).set(schedule.toJson());
  }

  // Update specific fields of a schedule
  Future<void> updateSchedule(
    String id,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _schedulesCollection.doc(id).update(updates);
  }

  // Toggle schedule enabled status
  Future<void> toggleSchedule(String id, bool enabled) async {
    await updateSchedule(id, {'enabled': enabled});
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id) async {
    await _schedulesCollection.doc(id).delete();
  }

  // Initialize default schedules if they don't exist
  Future<void> initializeDefaultSchedules() async {
    final weightDoc = await _schedulesCollection.doc('weight_reminder').get();
    if (!weightDoc.exists) {
      await saveSchedule(NotificationScheduleModel.defaultWeightReminder());
    }
  }
}
