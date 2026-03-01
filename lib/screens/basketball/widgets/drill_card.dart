import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../models/basketball_drill_model.dart';

class DrillCard extends StatelessWidget {
  final BasketballDrillModel drill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DrillCard({
    super.key,
    required this.drill,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _openVideoLink() async {
    if (drill.videoUrl == null || drill.videoUrl!.isEmpty) return;

    final url = drill.videoUrl!;
    final uri = Uri.tryParse(url);

    if (uri == null) {
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening video link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action buttons
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.sportsColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.sportsColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.sports_basketball_rounded,
                    color: AppColors.sportsColor,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.drillName,
                        style: AppTextStyles.bodyText
                            .adaptive(context)
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'By ${drill.createdBy}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: AppColors.sportsColor,
                    size: 20.w,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.all(8.w),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                    size: 20.w,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.all(8.w),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.description,
                  style: AppTextStyles.bodyText
                      .adaptive(context)
                      .copyWith(
                        fontSize: 14.sp,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkOnBackground
                            : AppColors.onBackground,
                        height: 1.4,
                      ),
                ),
                if (drill.videoUrl != null && drill.videoUrl!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: _openVideoLink,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sportsColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.sportsColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            color: AppColors.sportsColor,
                            size: 20.w,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              'Watch Video',
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.sportsColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: AppColors.sportsColor,
                            size: 16.w,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
