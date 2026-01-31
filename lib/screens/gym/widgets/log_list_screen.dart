import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/loading_indicator.dart';
import '../models/gym_workout_model.dart';
import '../providers/gym_provider.dart';
import 'workout_execution_screen.dart';

class LogListScreen extends ConsumerWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymProvider);
    // Show all workouts (both completed and incomplete)
    final allWorkouts = gymState.workoutHistory;

    if (gymState.isLoading && allWorkouts.isEmpty) {
      return const LoadingIndicator(message: 'Loading workout logs...');
    }

    if (allWorkouts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      itemCount: allWorkouts.length,
      itemBuilder: (context, index) {
        final workout = allWorkouts[index];
        return _LogListItem(workout: workout);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppColors.gymColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64.w,
              color: AppColors.gymColor,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No workout logs yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start a routine to create your first log',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _LogListItem extends ConsumerWidget {
  final GymWorkoutModel workout;

  const _LogListItem({required this.workout});

  void _handleDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${workout.routineName}" log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(gymProvider).deleteWorkout(workout.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('EEEE, MMM d').format(workout.date);
    final timeStr = DateFormat('h:mm a').format(workout.startTime);
    final durationStr = workout.duration > 0 ? '${workout.duration}m' : '';
    final isIncomplete = !workout.isCompleted;

    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutExecutionScreen(workout: workout),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateStr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gymColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isIncomplete)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'In Progress',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (durationStr.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    durationStr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') {
                    _handleDelete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            workout.routineName,
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Started at $timeStr',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey),
          ),
          if (workout.exercises.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: workout.exercises.take(4).map((ex) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    ex.exerciseName,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.sp,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (workout.exercises.length > 4)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  '+${workout.exercises.length - 4} more',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
