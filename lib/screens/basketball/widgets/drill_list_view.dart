import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/loading_indicator.dart';
import '../basketball_screen.dart';
import '../models/basketball_drill_model.dart';
import 'drill_card.dart';
import 'add_drill_bottom_sheet.dart';

class DrillListView extends ConsumerWidget {
  final String category;

  const DrillListView({super.key, required this.category});

  void _showEditSheet(
    BuildContext context,
    BasketballDrillModel drill,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDrillBottomSheet(
        category: category,
        existingDrill: drill,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BasketballDrillModel drill,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Drill?'),
        content: Text(
          'Are you sure you want to delete "${drill.drillName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(basketballProvider).deleteDrill(drill.id);
              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(basketballProvider);
    final drills = state.getDrillsByCategory(category);

    if (state.isLoading && state.allDrills.isEmpty) {
      return const LoadingIndicator(message: 'Loading drills...');
    }

    if (drills.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: drills.length,
      itemBuilder: (context, index) {
        final drill = drills[index];
        return DrillCard(
          drill: drill,
          onEdit: () => _showEditSheet(context, drill),
          onDelete: () => _confirmDelete(context, ref, drill),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.sportsColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_basketball_rounded,
              size: 48.w,
              color: AppColors.sportsColor,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No drills yet',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18.sp,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap + to add your first drill',
            style: AppTextStyles.bodyText.copyWith(
              fontSize: 14.sp,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
