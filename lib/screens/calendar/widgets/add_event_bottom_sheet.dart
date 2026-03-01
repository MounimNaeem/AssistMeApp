import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/calendar_event_model.dart';
import '../calendar_screen.dart';

class AddEventBottomSheet extends ConsumerStatefulWidget {
  final CalendarEventModel? existingEvent;
  final DateTime? initialDate;

  const AddEventBottomSheet({super.key, this.existingEvent, this.initialDate});

  @override
  ConsumerState<AddEventBottomSheet> createState() =>
      _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends ConsumerState<AddEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  late TimeOfDay _selectedEndTime;
  int _selectedColor = EventColors.blue;
  bool _reminderEnabled = false;
  int _reminderMinutesBefore = 30;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '5 minutes before', 'value': 5},
    {'label': '10 minutes before', 'value': 10},
    {'label': '15 minutes before', 'value': 15},
    {'label': '30 minutes before', 'value': 30},
    {'label': '1 hour before', 'value': 60},
    {'label': '2 hours before', 'value': 120},
    {'label': '1 day before', 'value': 1440},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final event = widget.existingEvent!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _selectedDate = event.eventDateTime;
      _selectedStartTime = TimeOfDay.fromDateTime(event.eventDateTime);
      _selectedEndTime = event.endDateTime != null
          ? TimeOfDay.fromDateTime(event.endDateTime!)
          : TimeOfDay(
              hour: _selectedStartTime.hour + 1,
              minute: _selectedStartTime.minute,
            );
      _selectedColor = event.eventColor;
      _reminderEnabled = event.reminderEnabled;
      _reminderMinutesBefore = event.reminderMinutesBefore;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedStartTime = TimeOfDay.now();
      _selectedEndTime = TimeOfDay(
        hour: TimeOfDay.now().hour + 1,
        minute: TimeOfDay.now().minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.calendarColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.calendarColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        // Auto-adjust end time to be 1 hour after start
        _selectedEndTime = TimeOfDay(
          hour: picked.hour + 1,
          minute: picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.calendarColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = ref.read(authProvider).currentUser;
      if (user == null) {
        setState(() => _isSaving = false);
        return;
      }

      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );

      DateTime? reminderAt;
      if (_reminderEnabled) {
        reminderAt = eventDateTime.subtract(
          Duration(minutes: _reminderMinutesBefore),
        );
      }

      // Check if reminder settings changed (for updates)
      final isReminderChanged =
          widget.existingEvent != null &&
          (widget.existingEvent!.reminderEnabled != _reminderEnabled ||
              widget.existingEvent!.reminderMinutesBefore !=
                  _reminderMinutesBefore ||
              widget.existingEvent!.eventDateTime != eventDateTime);

      // Reset reminderSent to false if:
      // - New event
      // - Reminder settings changed
      // - Event time changed
      final shouldResetReminderSent =
          widget.existingEvent == null || isReminderChanged;

      final event = CalendarEventModel(
        id: widget.existingEvent?.id ?? const Uuid().v4(),
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDateTime: eventDateTime,
        endDateTime: endDateTime,
        eventColor: _selectedColor,
        reminderEnabled: _reminderEnabled,
        reminderMinutesBefore: _reminderMinutesBefore,
        reminderAt: reminderAt,
        reminderSent: shouldResetReminderSent
            ? false
            : (widget.existingEvent?.reminderSent ?? false),
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
      );

      final calendarProv = ref.read(calendarProvider);

      if (widget.existingEvent != null) {
        await calendarProv.updateEvent(event.id, event);
      } else {
        await calendarProv.addEvent(event);
      }

      setState(() => _isSaving = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      padding: EdgeInsets.only(
        left: 28.w,
        right: 28.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                widget.existingEvent != null ? 'Edit Event' : 'New Event',
                style: AppTextStyles.heading1
                    .adaptive(context)
                    .copyWith(fontSize: 24.sp),
              ),
              SizedBox(height: 24.h),
              CustomTextField(
                controller: _titleController,
                label: 'Event Title',
                hint: 'e.g., Doctor Appointment',
                prefixIcon: const Icon(Icons.event_rounded),
                validator: (val) => val?.isEmpty == true ? 'Required' : null,
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Add event details...',
                prefixIcon: const Icon(Icons.notes_rounded),
                maxLines: 3,
                minLines: 2,
              ),
              SizedBox(height: 20.h),
              _buildColorPicker(),
              SizedBox(height: 20.h),
              _buildDateTimePickers(),
              SizedBox(height: 20.h),
              _buildReminderSection(),
              SizedBox(height: 32.h),
              CustomButton(
                text: widget.existingEvent != null
                    ? 'Update Event'
                    : 'Add Event',
                onPressed: _handleSave,
                isLoading: _isSaving,
                backgroundColor: AppColors.calendarColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Event Color',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                  : AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: List.generate(EventColors.all.length, (index) {
            final color = EventColors.all[index];
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.onBackground, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(color).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 18.w)
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        _buildDatePicker(),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _buildStartTimePicker()),
            SizedBox(width: 16.w),
            Expanded(child: _buildEndTimePicker()),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Date',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                  : AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkLightGrey
                    : AppColors.lightGrey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.calendarColor,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: AppTextStyles.bodyText
                        .adaptive(context)
                        .copyWith(fontSize: 14.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Start Time',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                  : AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _selectStartTime,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkLightGrey
                    : AppColors.lightGrey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColors.calendarColor,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _selectedStartTime.format(context),
                    style: AppTextStyles.bodyText
                        .adaptive(context)
                        .copyWith(fontSize: 14.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'End Time',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                  : AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _selectEndTime,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkLightGrey
                    : AppColors.lightGrey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColors.calendarColor,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _selectedEndTime.format(context),
                    style: AppTextStyles.bodyText
                        .adaptive(context)
                        .copyWith(fontSize: 14.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Reminder',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withValues(alpha: 0.7)
                  : AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkLightGrey
                  : AppColors.lightGrey,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.calendarColor,
                        size: 20.w,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Enable Reminder',
                        style: AppTextStyles.bodyText
                            .adaptive(context)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (value) =>
                        setState(() => _reminderEnabled = value),
                    activeTrackColor: AppColors.calendarColor.withValues(
                      alpha: 0.5,
                    ),
                    activeThumbColor: AppColors.calendarColor,
                  ),
                ],
              ),
              if (_reminderEnabled) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkElevated
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _reminderMinutesBefore,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.grey,
                      ),
                      items: _reminderOptions.map((option) {
                        return DropdownMenuItem<int>(
                          value: option['value'] as int,
                          child: Text(
                            option['label'] as String,
                            style: AppTextStyles.bodyText
                                .adaptive(context)
                                .copyWith(fontSize: 14.sp),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _reminderMinutesBefore = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
