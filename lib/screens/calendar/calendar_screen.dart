import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../utils/constants/colors.dart';
import '../../widgets/loading_indicator.dart';
import 'providers/calendar_provider.dart';
import 'models/calendar_event_model.dart';
import 'widgets/add_event_bottom_sheet.dart';

final calendarProvider = ChangeNotifierProvider((ref) => CalendarProvider());

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  final ScrollController _scrollController = ScrollController();
  DateTime _displayedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider).startListening();
    });
  }

  void _onViewChanged(ViewChangedDetails details) {
    // Update displayed month when user swipes
    if (details.visibleDates.isNotEmpty) {
      final midDate = details.visibleDates[details.visibleDates.length ~/ 2];
      if (midDate.month != _displayedMonth.month || midDate.year != _displayedMonth.year) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _displayedMonth = DateTime(midDate.year, midDate.month);
            });
          }
        });
      }
    }
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthYearPicker(
        initialDate: _displayedMonth,
        onDateSelected: (date) {
          setState(() {
            _displayedMonth = date;
          });
          _calendarController.displayDate = date;
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddEventSheet({
    CalendarEventModel? existingEvent,
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventBottomSheet(
        existingEvent: existingEvent,
        initialDate: initialDate,
      ),
    );
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell) {
      final selectedDate = details.date;
      if (selectedDate != null) {
        ref.read(calendarProvider).setSelectedDate(selectedDate);
      }
    } else if (details.targetElement == CalendarElement.appointment) {
      final appointment = details.appointments?.first;
      if (appointment != null && appointment is _EventAppointment) {
        _showEventDetails(appointment.event);
      }
    }
  }

  void _showEventDetails(CalendarEventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailsSheet(
        event: event,
        onEdit: () {
          Navigator.pop(context);
          _showAddEventSheet(existingEvent: event);
        },
        onDelete: () => _confirmDelete(event),
      ),
    );
  }

  void _confirmDelete(CalendarEventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(calendarProvider).deleteEvent(event.id);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: calendarState.isLoading && calendarState.events.isEmpty
          ? const LoadingIndicator(message: 'Loading events...')
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  title: const Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.calendarColor,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                ),
                // Calendar Card - Scrolls away
                SliverToBoxAdapter(child: _buildCalendarCard(calendarState)),
                // Events Header
                SliverToBoxAdapter(child: _buildEventsHeader(calendarState)),
                // Events List
                _buildEventsList(calendarState),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddEventSheet(initialDate: calendarState.selectedDate),
        backgroundColor: AppColors.calendarColor,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarCard(CalendarProvider calendarState) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Custom Header with Month/Year Picker
            _buildCustomCalendarHeader(),
            // Calendar
            SfCalendar(
              controller: _calendarController,
              view: CalendarView.month,
              dataSource: _EventDataSource(calendarState.events),
              onTap: _onCalendarTapped,
              onViewChanged: _onViewChanged,
              initialSelectedDate: calendarState.selectedDate,
              todayHighlightColor: AppColors.calendarColor,
              cellBorderColor: Colors.transparent,
              headerHeight: 0, // Hide default header
              selectionDecoration: BoxDecoration(
                color: AppColors.calendarColor.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.calendarColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              monthViewSettings: MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                showAgenda: false,
                dayFormat: 'EEE',
                numberOfWeeksInView: 6,
                showTrailingAndLeadingDates: true,
                monthCellStyle: MonthCellStyle(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackground,
                  ),
                  trailingDatesTextStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey.withValues(alpha: 0.4),
                  ),
                  leadingDatesTextStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey.withValues(alpha: 0.4),
                  ),
                ),
              ),
              viewHeaderStyle: ViewHeaderStyle(
                backgroundColor: Colors.white,
                dayTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey.withValues(alpha: 0.8),
                ),
              ),
              todayTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCalendarHeader() {
    final monthYearStr = DateFormat('MMMM yyyy').format(_displayedMonth);
    final isCurrentMonth = _displayedMonth.month == DateTime.now().month &&
        _displayedMonth.year == DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          GestureDetector(
            onTap: () {
              final prevMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
              setState(() => _displayedMonth = prevMonth);
              _calendarController.displayDate = prevMonth;
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.calendarColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.calendarColor,
                size: 20,
              ),
            ),
          ),
          // Month/Year Dropdown
          GestureDetector(
            onTap: _showMonthYearPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.calendarColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthYearStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.calendarColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.calendarColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Next Month / Today Button
          Row(
            children: [
              if (!isCurrentMonth)
                GestureDetector(
                  onTap: () {
                    final today = DateTime.now();
                    setState(() => _displayedMonth = DateTime(today.year, today.month));
                    _calendarController.displayDate = today;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.calendarColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  final nextMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                  setState(() => _displayedMonth = nextMonth);
                  _calendarController.displayDate = nextMonth;
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.calendarColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.calendarColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsHeader(CalendarProvider calendarState) {
    final eventsForDate = calendarState.getEventsForDate(
      calendarState.selectedDate,
    );
    final dateStr = _getDisplayDate(calendarState.selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.calendarColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${eventsForDate.length} ${eventsForDate.length == 1 ? 'event' : 'events'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.calendarColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayDate(DateTime date) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == todayDate) return 'Today';
    if (selectedDate == todayDate.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    if (selectedDate == todayDate.add(const Duration(days: 1))) {
      return 'Tomorrow';
    }
    return DateFormat('EEEE, MMM d').format(date);
  }

  Widget _buildEventsList(CalendarProvider calendarState) {
    final eventsForDate = calendarState.getEventsForDate(
      calendarState.selectedDate,
    );

    if (eventsForDate.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final event = eventsForDate[index];
          return _EventCard(
            event: event,
            onTap: () => _showEventDetails(event),
          );
        }, childCount: eventsForDate.length),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.calendarColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 40,
              color: AppColors.calendarColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No events',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap + to add an event',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEventModel event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(event.eventDateTime);
    final endTimeStr = event.endDateTime != null
        ? DateFormat('h:mm a').format(event.endDateTime!)
        : null;
    final isPast = event.eventDateTime.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: isPast
                    ? Color(event.eventColor).withValues(alpha: 0.4)
                    : Color(event.eventColor),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPast ? AppColors.grey : AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isPast
                            ? AppColors.grey
                            : AppColors.calendarColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        endTimeStr != null ? '$timeStr - $endTimeStr' : timeStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPast
                              ? AppColors.grey
                              : AppColors.calendarColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (event.reminderEnabled) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 14,
                          color: isPast
                              ? AppColors.grey
                              : AppColors.calendarColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final CalendarEventModel event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventDetailsSheet({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  String _getReminderText() {
    if (!event.reminderEnabled) return 'No reminder';
    final minutes = event.reminderMinutesBefore;
    if (minutes < 60) return '$minutes minutes before';
    if (minutes == 60) return '1 hour before';
    if (minutes < 1440) return '${minutes ~/ 60} hours before';
    return '1 day before';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(event.eventDateTime);
    final timeStr = DateFormat('h:mm a').format(event.eventDateTime);
    final endTimeStr = event.endDateTime != null
        ? DateFormat('h:mm a').format(event.endDateTime!)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(event.eventColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.calendarColor,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_rounded, dateStr),
          const SizedBox(height: 10),
          _buildDetailRow(
            Icons.access_time_rounded,
            endTimeStr != null ? '$timeStr - $endTimeStr' : timeStr,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            event.reminderEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            _getReminderText(),
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.lightGrey),
            const SizedBox(height: 10),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onBackground,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.calendarColor),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.onBackground),
          ),
        ),
      ],
    );
  }
}

/// Data source for Syncfusion calendar
class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<CalendarEventModel> events) {
    appointments = events.map((e) => _EventAppointment(e)).toList();
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as _EventAppointment).event.eventDateTime;
  }

  @override
  DateTime getEndTime(int index) {
    final event = (appointments![index] as _EventAppointment).event;
    return event.endDateTime ??
        event.eventDateTime.add(const Duration(hours: 1));
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as _EventAppointment).event.title;
  }

  @override
  Color getColor(int index) {
    final colorValue =
        (appointments![index] as _EventAppointment).event.eventColor;
    return Color(colorValue);
  }

  @override
  String? getNotes(int index) {
    return (appointments![index] as _EventAppointment).event.description;
  }
}

class _EventAppointment {
  final CalendarEventModel event;
  _EventAppointment(this.event);
}

/// Month/Year Picker Bottom Sheet
class _MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthYearPicker({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int _selectedYear;
  late int _selectedMonth;

  final List<String> _months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - 2 + i); // 2 years back, 7 years ahead

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          const Text(
            'Select Month & Year',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 20),
          // Year Selector
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = year == _selectedYear;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.calendarColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.calendarColor : AppColors.lightGrey,
                      ),
                    ),
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.onBackground,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Month Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == _selectedMonth;
              final isCurrentMonth = month == DateTime.now().month &&
                  _selectedYear == DateTime.now().year;

              return GestureDetector(
                onTap: () => setState(() => _selectedMonth = month),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.calendarColor
                        : isCurrentMonth
                            ? AppColors.calendarColor.withValues(alpha: 0.15)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected || isCurrentMonth
                          ? AppColors.calendarColor
                          : AppColors.lightGrey,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _months[index].substring(0, 3),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isCurrentMonth
                              ? AppColors.calendarColor
                              : AppColors.onBackground,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.calendarColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Go to ${_months[_selectedMonth - 1]} $_selectedYear',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
