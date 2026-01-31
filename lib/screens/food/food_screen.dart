import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../../widgets/loading_indicator.dart';
import '../home/providers/home_provider.dart';
import 'providers/food_provider.dart';
import 'widgets/add_food_bottom_sheet.dart';
import 'widgets/food_log_card.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodProvider).startListening();
    });
  }

  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFoodBottomSheet(),
    );
  }

  String _formatCalories(int calories) {
    return NumberFormat('#,###').format(calories);
  }

  Widget _buildAvgCaloriesHeader(int avgCalories, Map<String, int> avgMacros) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.success,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg (Last 3 Days)',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_formatCalories(avgCalories)} kcal',
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 20.sp,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroBadge('P', avgMacros['protein'] ?? 0, Colors.red),
              _buildMacroBadge(
                'C',
                avgMacros['carbs'] ?? 0,
                Colors.amber.shade700,
              ),
              _buildMacroBadge('F', avgMacros['fat'] ?? 0, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '${value}g',
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMacroBadge(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            '${value}g',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodProvider);
    final homeState = ref.watch(homeProvider);
    final avgCalories = homeState.getAverageCaloriesLast3Days(foodState);
    final avgMacros = foodState.getAverageMacrosLast3Days();
    final sortedDates = foodState.foodLogsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nutrition Log',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.foodColor,
        elevation: 0,
      ),
      body: foodState.isLoading && foodState.foodLogsByDate.isEmpty
          ? const LoadingIndicator(message: 'Loading your logs...')
          : foodState.foodLogsByDate.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildAvgCaloriesHeader(avgCalories, avgMacros),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final logs = foodState.foodLogsByDate[date]!;
                      final totalCalories = foodState.getTotalCaloriesForDate(
                        date,
                      );
                      final totalProtein = foodState.getTotalProteinForDate(
                        date,
                      );
                      final totalCarbs = foodState.getTotalCarbsForDate(date);
                      final totalFat = foodState.getTotalFatForDate(date);

                      String displayDate = _getDisplayDate(date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 8.w,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      displayDate,
                                      style: AppTextStyles.heading2.copyWith(
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.foodColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                      ),
                                      child: Text(
                                        '$totalCalories kcal',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.foodColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    _buildSmallMacroBadge(
                                      'P',
                                      totalProtein,
                                      Colors.red,
                                    ),
                                    SizedBox(width: 8.w),
                                    _buildSmallMacroBadge(
                                      'C',
                                      totalCarbs,
                                      Colors.amber.shade700,
                                    ),
                                    SizedBox(width: 8.w),
                                    _buildSmallMacroBadge(
                                      'F',
                                      totalFat,
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ...logs.map((log) => FoodLogCard(foodLog: log)),
                          SizedBox(height: 12.h),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodSheet,
        label: Text(
          'Log Meal',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: AppColors.foodColor,
        elevation: 4,
      ),
    );
  }

  String _getDisplayDate(String date) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    try {
      return DateFormat('EEEE, MMM d').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppColors.foodColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_rounded,
              size: 64.w,
              color: AppColors.foodColor,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No meals logged yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start tracking your daily nutrition!',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
