import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../../utils/routes/app_router.dart';
import '../../services/notification_service.dart';
import 'widgets/feature_card.dart';
import 'providers/home_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../food/providers/food_provider.dart';
import '../health_metrics/providers/health_metrics_provider.dart';
import '../study/study_screen.dart';
import '../assistant_management/assistant_management_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodProvider).startListening();
      ref.read(healthMetricsProvider).startListening();
      _saveFcmToken();
    });
  }

  void _saveFcmToken() {
    final user = ref.read(authProvider).currentUser;
    if (user != null) {
      NotificationService().saveTokenToFirestore(user.id);
    }
  }

  String _formatCalories(int calories) {
    return NumberFormat('#,###').format(calories);
  }

  Widget _buildDashboardStats(int avgCalories) {
    final metricsState = ref.watch(healthMetricsProvider);
    final latest = metricsState.latestMetrics;
    final calorieGoal = latest?.calorieGoal;

    // Determine color for avg calories based on goal
    Color avgCaloriesColor;
    if (calorieGoal == null || avgCalories == 0) {
      avgCaloriesColor = AppColors.foodColor; // Default orange
    } else if (avgCalories > calorieGoal) {
      avgCaloriesColor = Colors.red; // Over goal
    } else {
      avgCaloriesColor = Colors.green; // Under or at goal
    }

    final stats = [
      {
        'label': 'Avg Calories',
        'value': '${_formatCalories(avgCalories)} kcal',
        'icon': Icons.local_fire_department_rounded,
        'color': avgCaloriesColor,
      },
      {
        'label': 'Cal Goal',
        'value': calorieGoal != null ? '${_formatCalories(calorieGoal)} kcal' : '--',
        'icon': Icons.track_changes_rounded,
        'color': AppColors.foodColor,
      },
      {
        'label': 'Weight',
        'value': latest?.weight != null ? '${latest!.weight} kg' : '--',
        'icon': Icons.monitor_weight_rounded,
        'color': AppColors.gymColor,
      },
      {
        'label': 'BMI',
        'value': latest?.bmi != null ? '${latest!.bmi}' : '--',
        'icon': Icons.health_and_safety_rounded,
        'color': AppColors.primary,
      },
      {
        'label': 'Biceps',
        'value': latest?.biceps != null ? '${latest!.biceps} cm' : '--',
        'icon': Icons.fitness_center_rounded,
        'color': AppColors.secondary,
      },
      {
        'label': 'Waist',
        'value': latest?.waist != null ? '${latest!.waist} cm' : '--',
        'icon': Icons.accessibility_new_rounded,
        'color': AppColors.success,
      },
      {
        'label': 'Body Fat',
        'value': latest?.bodyFat != null ? '${latest!.bodyFat}%' : '--',
        'icon': Icons.percent_rounded,
        'color': AppColors.warning,
      },
      {
        'label': 'Muscle Mass',
        'value': latest?.muscleMass != null ? '${latest!.muscleMass} kg' : '--',
        'icon': Icons.bolt_rounded,
        'color': AppColors.info,
      },
    ];

    return Container(
      height: 90.h,
      margin: EdgeInsets.symmetric(vertical: 20.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          final isAvgCalories = index == 0;
          return Container(
            width: 100.w,
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: isAvgCalories
                  ? Border.all(color: stat['color'] as Color, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (stat['color'] as Color).withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 20.w,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final foodState = ref.watch(foodProvider);
    final homeState = ref.watch(homeProvider);
    final avgCalories = homeState.getAverageCaloriesLast3Days(foodState);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80.h,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, ${user?.name.split(' ')[0] ?? 'User'}!',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  user?.role == 'client' ? 'SUPER ADMIN' : 'ASSISTANT',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_suggest_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardStats(avgCalories),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Modules', style: AppTextStyles.heading2),
                  SizedBox(height: 16.h),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 26.w,
                    mainAxisSpacing: 26.h,
                    childAspectRatio: 1.3,
                    children: [
                      FeatureCard(
                        title: 'Food Log',
                        icon: Icons.restaurant_rounded,
                        color: AppColors.foodColor,
                        subtitle: 'Track Nutrition',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.food),
                      ),
                      FeatureCard(
                        title: 'Gym Workout',
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.gymColor,
                        subtitle: 'Log Progress',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.gym),
                      ),
                      FeatureCard(
                        title: 'Study Tasks',
                        icon: Icons.auto_stories_rounded,
                        color: AppColors.studyColor,
                        subtitle: 'Focus Mode',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudyScreen(),
                          ),
                        ),
                      ),
                      FeatureCard(
                        title: 'Calendar',
                        icon: Icons.event_available_rounded,
                        color: AppColors.calendarColor,
                        subtitle: 'Schedule',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.calendar),
                      ),
                      FeatureCard(
                        title: 'Basketball',
                        icon: Icons.sports_basketball_rounded,
                        color: AppColors.sportsColor,
                        subtitle: 'Game Stats',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.basketball),
                      ),
                      FeatureCard(
                        title: 'Health Metrics',
                        icon: Icons.monitor_heart_rounded,
                        color: AppColors.healthMetricsColor,
                        subtitle: 'Body Stats',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.healthMetrics),
                      ),
                      FeatureCard(
                        title: 'Notifications',
                        icon: Icons.notifications_rounded,
                        color: AppColors.notificationColor,
                        subtitle: 'Reminders',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.notificationSettings,
                        ),
                      ),
                      if (user?.role == 'client')
                        FeatureCard(
                          title: 'Assistant',
                          icon: Icons.person_add_alt_1_rounded,
                          color: AppColors.assistantColor,
                          subtitle: 'Manage Team',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssistantManagementScreen(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
