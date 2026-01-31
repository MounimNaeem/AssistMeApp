import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import 'providers/gym_provider.dart';
import 'widgets/log_list_screen.dart';
import 'widgets/routines_list_screen.dart';
import 'widgets/add_log_screen.dart';
import 'widgets/add_routine_screen.dart';

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> {
  int _currentIndex = 1; // Default to Routines tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gymProvider).startListeningToRoutines();
      ref.read(gymProvider).startListeningToWorkouts();
    });
  }

  void _onFabPressed() {
    if (_currentIndex == 0) {
      // Log tab - navigate to Add Log screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddLogScreen()),
      );
    } else {
      // Routines tab - navigate to Add Routine screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddRoutineScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.gymColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          _currentIndex == 0 ? 'Log' : 'Routines',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              // Menu options
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          LogListScreen(),
          RoutinesListScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: AppColors.gymColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.history_rounded,
                  label: 'Log',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.fitness_center_rounded,
                  label: 'Routines',
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gymColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gymColor : AppColors.grey,
              size: 24.w,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.gymColor : AppColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
