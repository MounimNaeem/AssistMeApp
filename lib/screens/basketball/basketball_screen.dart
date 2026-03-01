import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import 'providers/basketball_provider.dart';
import 'models/basketball_drill_model.dart';
import 'widgets/drill_list_view.dart';
import 'widgets/add_drill_bottom_sheet.dart';

final basketballProvider = ChangeNotifierProvider(
  (ref) => BasketballProvider(),
);

class BasketballScreen extends ConsumerStatefulWidget {
  const BasketballScreen({super.key});

  @override
  ConsumerState<BasketballScreen> createState() => _BasketballScreenState();
}

class _BasketballScreenState extends ConsumerState<BasketballScreen> {
  int _currentIndex = 0;

  final List<String> _categories = [
    DrillCategory.finishing,
    DrillCategory.shooting,
    DrillCategory.handles,
    DrillCategory.conditioning,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(basketballProvider).startListening();
    });
  }

  void _onFabPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDrillBottomSheet(category: _categories[_currentIndex]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCategory = _categories[_currentIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.sportsColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          DrillCategory.getDisplayName(currentCategory),
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _categories
            .map((category) => DrillListView(category: category))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: AppColors.sportsColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.sports_basketball_rounded,
                  label: 'Finishing',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.sports_score_rounded,
                  label: 'Shooting',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.back_hand_rounded,
                  label: 'Handles',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.directions_run_rounded,
                  label: 'Conditioning',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sportsColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.sportsColor : AppColors.grey,
              size: 24.w,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.sportsColor : AppColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
