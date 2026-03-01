import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/text_styles.dart';
import '../../../../widgets/custom_card.dart';
import '../models/food_log_model.dart';
import '../widgets/food_detail_bottom_sheet.dart';

class FoodLogCard extends StatelessWidget {
  final FoodLogModel foodLog;

  const FoodLogCard({super.key, required this.foodLog});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FoodDetailBottomSheet(foodLog: foodLog),
        );
      },
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _getMealColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(_getMealIcon(), color: _getMealColor(), size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodLog.mealName,
                  style: AppTextStyles.bodyText
                      .adaptive(context)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${DateFormat('h:mm a').format(foodLog.time)} • ${foodLog.mealType}',
                  style: AppTextStyles.caption
                      .adaptive(context)
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                if (_hasMacros()) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      if (foodLog.protein != null)
                        _buildMacroLabel(
                          'P',
                          foodLog.protein!,
                          Colors.red.shade400,
                        ),
                      if (foodLog.carbs != null) ...[
                        SizedBox(width: 8.w),
                        _buildMacroLabel(
                          'C',
                          foodLog.carbs!,
                          Colors.amber.shade600,
                        ),
                      ],
                      if (foodLog.fat != null) ...[
                        SizedBox(width: 8.w),
                        _buildMacroLabel(
                          'F',
                          foodLog.fat!,
                          Colors.blue.shade400,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${foodLog.calories}',
                style: AppTextStyles.heading2
                    .adaptive(context)
                    .copyWith(
                      fontSize: 18.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkOnBackground
                          : AppColors.onBackground,
                    ),
              ),
              Text(
                'kcal',
                style: AppTextStyles.caption
                    .adaptive(context)
                    .copyWith(fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon() {
    switch (foodLog.mealType) {
      case 'Breakfast':
        return Icons.wb_twilight_rounded;
      case 'Lunch':
        return Icons.wb_sunny_rounded;
      case 'Dinner':
        return Icons.nightlight_round;
      default:
        return Icons.apple_rounded;
    }
  }

  Color _getMealColor() {
    switch (foodLog.mealType) {
      case 'Breakfast':
        return Colors.orange;
      case 'Lunch':
        return Colors.blue;
      case 'Dinner':
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }

  bool _hasMacros() {
    return foodLog.protein != null ||
        foodLog.carbs != null ||
        foodLog.fat != null;
  }

  Widget _buildMacroLabel(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$label: ${value}g',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
