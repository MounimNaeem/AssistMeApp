import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../../widgets/loading_indicator.dart';
import 'models/notification_schedule_model.dart';
import 'providers/notification_settings_provider.dart';
import 'widgets/edit_schedule_bottom_sheet.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationSettingsProvider).startListening();
    });
  }

  void _showEditSheet(NotificationScheduleModel schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditScheduleBottomSheet.edit(schedule: schedule),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditScheduleBottomSheet.create(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.notificationColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.notificationColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: state.isLoading && state.schedules.isEmpty
          ? const LoadingIndicator(message: 'Loading settings...')
          : state.schedules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 20.w,
                    bottom: 80.h, // Extra padding for FAB
                  ),
                  itemCount: state.schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = state.schedules[index];
                    return _buildScheduleCard(schedule);
                  },
                ),
    );
  }

  Widget _buildScheduleCard(NotificationScheduleModel schedule) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.notificationColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSheet(schedule),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.notificationColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: AppColors.notificationColor,
                        size: 24.w,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.displayName,
                            style: AppTextStyles.heading2.copyWith(
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            schedule.frequencyDisplay,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.notificationColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: schedule.enabled,
                      onChanged: (value) {
                        ref
                            .read(notificationSettingsProvider)
                            .toggleSchedule(schedule.id, value);
                      },
                      activeTrackColor:
                          AppColors.notificationColor.withValues(alpha: 0.5),
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.notificationColor;
                        }
                        return null;
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.title_rounded,
                            size: 16.w,
                            color: AppColors.grey,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              schedule.title,
                              style: AppTextStyles.bodyText.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.message_rounded,
                            size: 16.w,
                            color: AppColors.grey,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              schedule.body,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16.w,
                            color: AppColors.grey,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _formatTime(schedule.preferredTime),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to edit',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.grey,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.edit_rounded,
                      size: 14.w,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: AppColors.notificationColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 64.w,
                color: AppColors.notificationColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No notifications yet',
              style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create reminders to stay on track with your health goals',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _showCreateSheet,
              icon: const Icon(Icons.add),
              label: const Text('Create Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.notificationColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
