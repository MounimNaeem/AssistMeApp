import 'dart:async';
import 'package:flutter/material.dart';
import '../models/calendar_event_model.dart';
import '../services/calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  final CalendarService _service = CalendarService();
  StreamSubscription<List<CalendarEventModel>>? _subscription;

  bool isLoading = false;
  String? errorMessage;
  List<CalendarEventModel> events = [];
  DateTime selectedDate = DateTime.now();

  /// Get events for a specific date
  List<CalendarEventModel> getEventsForDate(DateTime date) {
    return events.where((event) {
      return event.eventDateTime.year == date.year &&
          event.eventDateTime.month == date.month &&
          event.eventDateTime.day == date.day;
    }).toList()
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
  }

  /// Get upcoming events (from today onwards)
  List<CalendarEventModel> get upcomingEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return events
        .where((event) => event.eventDateTime.isAfter(today) ||
            (event.eventDateTime.year == today.year &&
             event.eventDateTime.month == today.month &&
             event.eventDateTime.day == today.day))
        .toList()
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
  }

  /// Check if a date has events
  bool hasEventsOnDate(DateTime date) {
    return events.any((event) =>
        event.eventDateTime.year == date.year &&
        event.eventDateTime.month == date.month &&
        event.eventDateTime.day == date.day);
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  /// Starts listening to real-time calendar events (shared across all users)
  void startListening() {
    if (_subscription != null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _subscription = _service.getEventsStream().listen(
      (eventsList) {
        events = eventsList;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stops listening to real-time updates
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> addEvent(CalendarEventModel event) async {
    try {
      await _service.addEvent(event);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateEvent(String eventId, CalendarEventModel event) async {
    try {
      await _service.updateEvent(eventId, event);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _service.deleteEvent(eventId);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
