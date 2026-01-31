import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event_model.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'calendar_events';

  /// Returns a real-time stream of all calendar events (shared across all users)
  Stream<List<CalendarEventModel>> getEventsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('eventDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEventModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get events for a specific date range
  Stream<List<CalendarEventModel>> getEventsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collection)
        .where('eventDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('eventDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('eventDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEventModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addEvent(CalendarEventModel event) async {
    await _firestore.collection(_collection).doc(event.id).set(event.toJson());
  }

  Future<void> updateEvent(String eventId, CalendarEventModel event) async {
    await _firestore.collection(_collection).doc(eventId).update(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(_collection).doc(eventId).delete();
  }
}
