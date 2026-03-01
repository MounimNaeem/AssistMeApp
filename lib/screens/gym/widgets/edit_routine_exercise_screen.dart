import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/exercise_template_model.dart';

class EditRoutineExerciseScreen extends StatefulWidget {
  final ExerciseTemplateModel exercise;

  const EditRoutineExerciseScreen({super.key, required this.exercise});

  @override
  State<EditRoutineExerciseScreen> createState() =>
      _EditRoutineExerciseScreenState();
}

class _EditRoutineExerciseScreenState extends State<EditRoutineExerciseScreen> {
  late TextEditingController _setsController;
  late TextEditingController _warmUpSetsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.exercise.plannedSets.toString(),
    );
    _warmUpSetsController = TextEditingController(
      text: widget.exercise.warmUpSets.toString(),
    );
    _notesController = TextEditingController(text: widget.exercise.notes);
  }

  @override
  void dispose() {
    _setsController.dispose();
    _warmUpSetsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    final sets =
        int.tryParse(_setsController.text) ?? widget.exercise.plannedSets;
    final warmUpSets =
        int.tryParse(_warmUpSetsController.text) ?? widget.exercise.warmUpSets;

    final updatedExercise = widget.exercise.copyWith(
      plannedSets: sets,
      warmUpSets: warmUpSets,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, updatedExercise);
  }

  void _handleReplace() {
    // Navigate to exercise selection screen
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replace functionality coming soon')),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${widget.exercise.exerciseName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, null); // Return null to indicate deletion
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.gymColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.exercise.exerciseName,
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () {
              // Help info
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Info Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Sets Field
                  CustomTextField(
                    controller: _setsController,
                    label: 'Sets',
                    hint: 'Number of sets',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.h),

                  // Warm Up Sets Field
                  CustomTextField(
                    controller: _warmUpSetsController,
                    label: 'Warm Up Sets',
                    hint: 'Number of warm up sets',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.h),

                  // Notes Field
                  CustomTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Add notes...',
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Replace Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleReplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gymColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Replace',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Update Button (floating at bottom)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Update Exercise',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
