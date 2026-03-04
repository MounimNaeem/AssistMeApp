import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/notification_schedule_model.dart';
import '../providers/notification_settings_provider.dart';

class EditScheduleBottomSheet extends ConsumerStatefulWidget {
  final NotificationScheduleModel? schedule;
  final bool isEditMode;

  const EditScheduleBottomSheet({
    super.key,
    this.schedule,
    this.isEditMode = true,
  });

  /// Factory constructor for creating a new notification
  factory EditScheduleBottomSheet.create({Key? key}) {
    return EditScheduleBottomSheet(key: key, schedule: null, isEditMode: false);
  }

  /// Factory constructor for editing an existing notification
  factory EditScheduleBottomSheet.edit({
    Key? key,
    required NotificationScheduleModel schedule,
  }) {
    return EditScheduleBottomSheet(
      key: key,
      schedule: schedule,
      isEditMode: true,
    );
  }

  @override
  ConsumerState<EditScheduleBottomSheet> createState() =>
      _EditScheduleBottomSheetState();
}

class _EditScheduleBottomSheetState
    extends ConsumerState<EditScheduleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _frequencyController;
  late String _frequencyType;
  late TimeOfDay _selectedTime;
  late List<String> _selectedDays;
  late NotificationScheduleModel _workingSchedule;

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    // Use existing schedule or create a new one
    _workingSchedule = widget.schedule ?? NotificationScheduleModel.createNew();

    _titleController = TextEditingController(text: _workingSchedule.title);
    _bodyController = TextEditingController(text: _workingSchedule.body);
    _frequencyController = TextEditingController(
      text: _workingSchedule.frequencyValue.toString(),
    );
    _frequencyType = _workingSchedule.frequencyType;
    _selectedTime = _parseTime(_workingSchedule.preferredTime);
    _selectedDays = _workingSchedule.selectedDays.isNotEmpty
        ? List<String>.from(_workingSchedule.selectedDays)
        : ['Mon', 'Wed', 'Fri'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getFrequencyPreview() {
    final timeStr = _formatTimeDisplay(_selectedTime);
    final frequencyValue = int.tryParse(_frequencyController.text) ?? 1;

    switch (_frequencyType) {
      case 'daily':
        return 'You will receive notification every day at $timeStr';
      case 'days':
        if (frequencyValue == 1) {
          return 'You will receive notification every day at $timeStr';
        }
        return 'You will receive notification every $frequencyValue days at $timeStr';
      case 'weekly':
        return 'You will receive notification every week at $timeStr';
      case 'weeks':
        if (frequencyValue == 1) {
          return 'You will receive notification every week at $timeStr';
        }
        return 'You will receive notification every $frequencyValue weeks at $timeStr';
      case 'months':
        if (frequencyValue == 1) {
          return 'You will receive notification every month at $timeStr';
        }
        return 'You will receive notification every $frequencyValue months at $timeStr';
      case 'selected_days':
        if (_selectedDays.isEmpty) {
          return 'Please select at least one day';
        }
        return 'You will receive notification on ${_selectedDays.join(", ")} at $timeStr';
      default:
        return 'You will receive notification at $timeStr';
    }
  }

  bool get _showFrequencyValue {
    return _frequencyType == 'days' ||
        _frequencyType == 'weeks' ||
        _frequencyType == 'months';
  }

  bool get _showDaySelector {
    return _frequencyType == 'selected_days';
  }

  Future<void> _selectTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.notificationColor,
                    onPrimary: Colors.white,
                    surface: AppColors.darkCard,
                    onSurface: AppColors.darkOnBackground,
                  )
                : ColorScheme.light(
                    primary: AppColors.notificationColor,
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
        _selectedTime = picked;
      });
    }
  }

  /// Calculate the next scheduled time
  /// The time picker shows LOCAL time (device timezone)
  /// We store the time as-is and convert to UTC for scheduling
  DateTime _calculateNextScheduledAt() {
    final now = DateTime.now();

    // Create a DateTime with the selected time in local timezone
    DateTime nextDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (nextDate.isBefore(now)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }

    // For selected_days, find the next matching day
    if (_frequencyType == 'selected_days' && _selectedDays.isNotEmpty) {
      final dayMap = {
        'Sun': DateTime.sunday,
        'Mon': DateTime.monday,
        'Tue': DateTime.tuesday,
        'Wed': DateTime.wednesday,
        'Thu': DateTime.thursday,
        'Fri': DateTime.friday,
        'Sat': DateTime.saturday,
      };
      final selectedDayNums = _selectedDays.map((d) => dayMap[d]!).toList();

      // Find next matching day
      for (int i = 0; i < 7; i++) {
        if (selectedDayNums.contains(nextDate.weekday)) {
          break;
        }
        nextDate = nextDate.add(const Duration(days: 1));
      }
    }

    return nextDate;
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate selected days for 'selected_days' frequency
    if (_frequencyType == 'selected_days' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    // Calculate next scheduled time based on new settings
    final nextScheduledAt = _calculateNextScheduledAt();

    final updatedSchedule = _workingSchedule.copyWith(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      frequencyType: _frequencyType,
      frequencyValue: int.tryParse(_frequencyController.text.trim()) ?? 1,
      preferredTime: _formatTimeOfDay(_selectedTime),
      selectedDays: _frequencyType == 'selected_days' ? _selectedDays : [],
      nextScheduledAt: nextScheduledAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(notificationSettingsProvider).saveSchedule(updatedSchedule);

    if (mounted) Navigator.pop(context);
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(notificationSettingsProvider)
          .deleteSchedule(_workingSchedule.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(notificationSettingsProvider).isLoading;

    return Container(
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkLightGrey
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditMode
                        ? 'Edit Notification'
                        : 'New Notification',
                    style: AppTextStyles.heading1
                        .adaptive(context)
                        .copyWith(fontSize: 24.sp),
                  ),
                  if (widget.isEditMode)
                    IconButton(
                      onPressed: _handleDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 24.w,
                      ),
                      tooltip: 'Delete notification',
                    ),
                ],
              ),
              SizedBox(height: 24.h),

              // Title
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Notification title',
                prefixIcon: const Icon(Icons.title_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Body - 3 lines
              CustomTextField(
                controller: _bodyController,
                label: 'Message',
                hint: 'Enter notification message...',
                maxLines: 3,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Message is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // Frequency section
              Text(
                'Frequency',
                style: AppTextStyles.heading2
                    .adaptive(context)
                    .copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),

              // Frequency type dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCard
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkLightGrey
                        : AppColors.lightGrey,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _frequencyType,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.notificationColor,
                    ),
                    style: AppTextStyles.bodyText
                        .adaptive(context)
                        .copyWith(fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(
                        value: 'days',
                        child: Text('Every X Days'),
                      ),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                        value: 'weeks',
                        child: Text('Every X Weeks'),
                      ),
                      DropdownMenuItem(
                        value: 'months',
                        child: Text('Every X Months'),
                      ),
                      DropdownMenuItem(
                        value: 'selected_days',
                        child: Text('Selected Days'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _frequencyType = value;
                          if (value == 'daily' || value == 'weekly') {
                            _frequencyController.text = '1';
                          }
                        });
                      }
                    },
                  ),
                ),
              ),

              // Frequency value input (for days, weeks, months)
              if (_showFrequencyValue) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Text(
                      'Every',
                      style: AppTextStyles.bodyText.adaptive(context),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 70.w,
                      child: TextFormField(
                        controller: _frequencyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.bodyText.adaptive(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkCard
                              : Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 14.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkLightGrey
                                  : AppColors.lightGrey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColors.notificationColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final num = int.tryParse(value ?? '');
                          if (num == null || num < 1) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      _frequencyType == 'days'
                          ? 'days'
                          : _frequencyType == 'weeks'
                          ? 'weeks'
                          : 'months',
                      style: AppTextStyles.bodyText.adaptive(context),
                    ),
                  ],
                ),
              ],

              // Day selector (for selected_days)
              if (_showDaySelector) ...[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _weekDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.notificationColor
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCard
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.notificationColor
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkLightGrey
                                      : AppColors.lightGrey),
                          ),
                        ),
                        child: Text(
                          day,
                          style: AppTextStyles.bodyText
                              .adaptive(context)
                              .copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkGrey
                                          : AppColors.grey),
                              ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Frequency preview
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.notificationColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.notificationColor,
                      size: 20.w,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _getFrequencyPreview(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.notificationColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Time picker
              Text(
                'Preferred Time',
                style: AppTextStyles.heading2
                    .adaptive(context)
                    .copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),

              InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
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
                        color: AppColors.notificationColor,
                        size: 24.w,
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        _formatTimeDisplay(_selectedTime),
                        style: AppTextStyles.bodyText.adaptive(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkGrey
                            : AppColors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              CustomButton(
                text: widget.isEditMode
                    ? 'Save Changes'
                    : 'Create Notification',
                onPressed: _handleSave,
                isLoading: isLoading,
                backgroundColor: AppColors.notificationColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
