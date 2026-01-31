import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../models/health_metrics_model.dart';
import '../providers/health_metrics_provider.dart';
import 'add_health_metrics_bottom_sheet.dart';

class HealthMetricsCard extends ConsumerWidget {
  final HealthMetricsModel metrics;

  const HealthMetricsCard({super.key, required this.metrics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.healthMetricsColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSheet(context),
          onLongPress: () => _showDeleteDialog(context, ref),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.healthMetricsColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.monitor_heart_rounded,
                            color: AppColors.healthMetricsColor,
                            size: 18.w,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          _formatTime(metrics.updatedAt),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 18.w,
                            color: AppColors.grey,
                          ),
                          onPressed: () => _showEditSheet(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18.w,
                            color: AppColors.error,
                          ),
                          onPressed: () => _showDeleteDialog(context, ref),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 16.w,
                  runSpacing: 8.h,
                  children: _buildMetricChips(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMetricChips() {
    final chips = <Widget>[];

    if (metrics.weight != null) {
      chips.add(_buildChip('Weight', '${metrics.weight} kg', Icons.monitor_weight_rounded));
    }
    if (metrics.height != null) {
      chips.add(_buildChip('Height', '${metrics.height} cm', Icons.height_rounded));
    }
    if (metrics.bmi != null) {
      chips.add(_buildChip('BMI', '${metrics.bmi}', Icons.health_and_safety_rounded));
    }
    if (metrics.biceps != null) {
      chips.add(_buildChip('Biceps', '${metrics.biceps} cm', Icons.fitness_center_rounded));
    }
    if (metrics.waist != null) {
      chips.add(_buildChip('Waist', '${metrics.waist} cm', Icons.accessibility_new_rounded));
    }
    if (metrics.bodyFat != null) {
      chips.add(_buildChip('Body Fat', '${metrics.bodyFat}%', Icons.percent_rounded));
    }
    if (metrics.muscleMass != null) {
      chips.add(_buildChip('Muscle', '${metrics.muscleMass} kg', Icons.bolt_rounded));
    }
    if (metrics.calorieGoal != null) {
      chips.add(_buildChip('Cal Goal', '${metrics.calorieGoal} kcal', Icons.local_fire_department_rounded));
    }

    return chips;
  }

  Widget _buildChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: AppColors.healthMetricsColor),
          SizedBox(width: 4.w),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHealthMetricsBottomSheet(existingMetrics: metrics),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: const Text('Are you sure you want to delete this measurement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(healthMetricsProvider).deleteHealthMetrics(metrics.id);
              Navigator.pop(ctx);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
