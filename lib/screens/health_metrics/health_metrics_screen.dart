import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../../widgets/loading_indicator.dart';
import 'providers/health_metrics_provider.dart';
import 'widgets/add_health_metrics_bottom_sheet.dart';
import 'widgets/health_metrics_card.dart';

class HealthMetricsScreen extends ConsumerStatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  ConsumerState<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends ConsumerState<HealthMetricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthMetricsProvider).startListening();
    });
  }

  void _showAddMetricsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddHealthMetricsBottomSheet(),
    );
  }

  Widget _buildLatestMetricsHeader() {
    final metricsState = ref.watch(healthMetricsProvider);
    final latest = metricsState.latestMetrics;

    if (latest == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.healthMetricsColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.healthMetricsColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  color: AppColors.healthMetricsColor,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Measurements',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(latest.date),
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.healthMetricsColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildMetricsGrid(latest),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(dynamic latest) {
    final metrics = [
      if (latest.weight != null)
        {'label': 'Weight', 'value': '${latest.weight} kg', 'icon': Icons.monitor_weight_rounded},
      if (latest.height != null)
        {'label': 'Height', 'value': '${latest.height} cm', 'icon': Icons.height_rounded},
      if (latest.bmi != null)
        {'label': 'BMI', 'value': '${latest.bmi}', 'icon': Icons.health_and_safety_rounded},
      if (latest.biceps != null)
        {'label': 'Biceps', 'value': '${latest.biceps} cm', 'icon': Icons.fitness_center_rounded},
      if (latest.waist != null)
        {'label': 'Waist', 'value': '${latest.waist} cm', 'icon': Icons.accessibility_new_rounded},
      if (latest.bodyFat != null)
        {'label': 'Body Fat', 'value': '${latest.bodyFat}%', 'icon': Icons.percent_rounded},
      if (latest.muscleMass != null)
        {'label': 'Muscle', 'value': '${latest.muscleMass} kg', 'icon': Icons.bolt_rounded},
      if (latest.calorieGoal != null)
        {'label': 'Cal Goal', 'value': '${latest.calorieGoal} kcal', 'icon': Icons.local_fire_department_rounded},
    ];

    if (metrics.isEmpty) {
      return Text(
        'No measurements recorded',
        style: AppTextStyles.caption,
      );
    }

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: metrics.map((metric) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metric['icon'] as IconData,
                size: 16.w,
                color: AppColors.healthMetricsColor,
              ),
              SizedBox(width: 6.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric['value'] as String,
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    metric['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(String date) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _getDisplayDate(String date) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    try {
      return DateFormat('EEEE, MMM d').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metricsState = ref.watch(healthMetricsProvider);
    final sortedDates = metricsState.metricsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health Metrics',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.healthMetricsColor,
        elevation: 0,
      ),
      body: metricsState.isLoading && metricsState.metricsByDate.isEmpty
          ? const LoadingIndicator(message: 'Loading your metrics...')
          : metricsState.metricsByDate.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildLatestMetricsHeader(),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final metrics = metricsState.metricsByDate[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 16.h,
                                  horizontal: 8.w,
                                ),
                                child: Text(
                                  _getDisplayDate(date),
                                  style: AppTextStyles.heading2.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                ),
                              ),
                              ...metrics.map((metric) => HealthMetricsCard(metrics: metric)),
                              SizedBox(height: 12.h),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMetricsSheet,
        label: Text(
          'Add Metrics',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: AppColors.healthMetricsColor,
        elevation: 4,
      ),
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
              color: AppColors.healthMetricsColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monitor_heart_rounded,
              size: 64.w,
              color: AppColors.healthMetricsColor,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No metrics logged yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start tracking your health measurements!',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
