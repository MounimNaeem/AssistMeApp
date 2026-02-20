import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../screens/calendar/models/calendar_event_model.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'TodayEventsWidget';
  static const String _dailyFitnessWidgetName = 'DailyFitnessWidget';

  // iOS widget names
  static const String _iOSWidgetName = 'TodayEventsWidget';
  static const String _iOSDailyFitnessWidgetName = 'DailyFitnessWidget';

  /// Updates the home widget with events for today and nearby days
  static Future<void> updateTodayEvents(List<CalendarEventModel> allEvents) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('h:mm a');

    // Save events for today and the next/previous 7 days for navigation
    for (int offset = -7; offset <= 7; offset++) {
      final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      final nextDay = targetDate.add(const Duration(days: 1));

      // Filter events for this day
      final dayEvents = allEvents
          .where((e) =>
              e.eventDateTime.isAfter(targetDate.subtract(const Duration(seconds: 1))) &&
              e.eventDateTime.isBefore(nextDay))
          .toList()
        ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      // Format events for widget
      final eventsData = dayEvents.map((event) {
        return {
          'title': event.title,
          'time': timeFormat.format(event.eventDateTime),
          'color': event.eventColor,
        };
      }).toList();

      final dateKey = dateFormat.format(targetDate);

      if (offset == 0) {
        // Save as today_events for backward compatibility
        await HomeWidget.saveWidgetData<String>(
          'today_events',
          jsonEncode(eventsData),
        );
      }

      // Save with date-specific key
      await HomeWidget.saveWidgetData<String>(
        'events_$dateKey',
        jsonEncode(eventsData),
      );
    }

    // Trigger widget update for both Android and iOS
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  /// Clears widget data
  static Future<void> clearWidget() async {
    await HomeWidget.saveWidgetData<String>('today_events', '[]');
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  /// Updates the daily fitness widget with calories and gym streak
  static Future<void> updateDailyFitness({
    required int totalCalories,
    required int gymStreak,
    required bool hasLoggedToday,
  }) async {
    try {
      // Save calories data
      await HomeWidget.saveWidgetData<int>('total_calories', totalCalories);

      // Save gym streak data
      await HomeWidget.saveWidgetData<int>('gym_streak', gymStreak);

      // Save whether user has logged today
      await HomeWidget.saveWidgetData<bool>('has_logged_today', hasLoggedToday);

      // Trigger widget update for both Android and iOS
      await HomeWidget.updateWidget(
        androidName: _dailyFitnessWidgetName,
        iOSName: _iOSDailyFitnessWidgetName,
      );
    } catch (e) {
      print('Error updating daily fitness widget: $e');
    }
  }

  /// Clears daily fitness widget data
  static Future<void> clearDailyFitnessWidget() async {
    await HomeWidget.saveWidgetData<int>('total_calories', 0);
    await HomeWidget.saveWidgetData<int>('gym_streak', 0);
    await HomeWidget.saveWidgetData<bool>('has_logged_today', false);
    await HomeWidget.updateWidget(
      androidName: _dailyFitnessWidgetName,
      iOSName: _iOSDailyFitnessWidgetName,
    );
  }

  /// Updates only calories data (preserves existing gym data)
  static Future<void> updateCalories(int totalCalories) async {
    try {
      await HomeWidget.saveWidgetData<int>('total_calories', totalCalories);
      await HomeWidget.updateWidget(
        androidName: _dailyFitnessWidgetName,
        iOSName: _iOSDailyFitnessWidgetName,
      );
    } catch (e) {
      print('Error updating calories: $e');
    }
  }

  /// Updates only gym data (preserves existing calories data)
  static Future<void> updateGymData({
    required int gymStreak,
    required bool hasLoggedToday,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('gym_streak', gymStreak);
      await HomeWidget.saveWidgetData<bool>('has_logged_today', hasLoggedToday);
      await HomeWidget.updateWidget(
        androidName: _dailyFitnessWidgetName,
        iOSName: _iOSDailyFitnessWidgetName,
      );
    } catch (e) {
      print('Error updating gym data: $e');
    }
  }
}
