import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/text_styles.dart';
import '../../../../widgets/custom_button.dart';
import '../models/food_log_model.dart';
import '../providers/food_provider.dart';
import 'add_food_bottom_sheet.dart';

class FoodDetailBottomSheet extends ConsumerWidget {
  final FoodLogModel foodLog;

  const FoodDetailBottomSheet({super.key, required this.foodLog});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Food Log?'),
        content: const Text('Are you sure you want to delete this food log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close sheet
              await ref.read(foodProvider).deleteFoodLog(foodLog.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Food Details', style: AppTextStyles.heading2),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          _buildDetailRow('Meal Name', foodLog.mealName, isBold: true),
          _buildDetailRow('Meal Type', foodLog.mealType),
          _buildDetailRow('Calories', '${foodLog.calories} cal'),
          _buildDetailRow('Servings', '${foodLog.numberOfServings}'),
          _buildDetailRow('Serving Size', foodLog.servingSize),
          _buildDetailRow('Time', DateFormat('h:mm a').format(foodLog.time)),
          _buildDetailRow('Date', DateFormat('MMM d, yyyy').format(foodLog.time)),

          // Macros Section
          if (foodLog.protein != null || foodLog.carbs != null || foodLog.fat != null) ...[
            SizedBox(height: 16.h),
            Divider(color: AppColors.lightGrey),
            SizedBox(height: 12.h),
            Text('Macros', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroChip('Protein', foodLog.protein, Colors.red.shade400),
                _buildMacroChip('Carbs', foodLog.carbs, Colors.amber.shade600),
                _buildMacroChip('Fat', foodLog.fat, Colors.blue.shade400),
              ],
            ),
          ],

          SizedBox(height: 32.h),
          
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit',
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                      ),
                      builder: (_) => AddFoodBottomSheet(existingLog: foodLog),
                    );
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomButton(
                  text: 'Delete',
                  backgroundColor: AppColors.error,
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyText.copyWith(color: AppColors.grey)),
          Text(
            value,
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18.sp : 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, int? value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            value != null ? '${value}g' : '-',
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
