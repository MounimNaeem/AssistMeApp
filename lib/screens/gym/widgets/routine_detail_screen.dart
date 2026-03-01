import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/gym_routine_model.dart';
import '../models/exercise_template_model.dart';
import '../providers/gym_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_exercise_screen.dart';
import 'edit_routine_exercise_screen.dart';
import 'workout_execution_screen.dart';

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  String _selectedTarget = 'Latest';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeControllers(GymRoutineModel routine) {
    if (!_isEditing) {
      _nameController.text = routine.routineName;
      _notesController.text = routine.notes;
      _selectedTarget = routine.target;
    }
  }

  Future<void> _handleStart(GymRoutineModel routine) async {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId == null) return;

    // Check if there's an incomplete workout for this routine
    final incompleteWorkout = ref
        .read(gymProvider)
        .getIncompleteWorkoutForRoutine(routine.id);

    if (incompleteWorkout != null) {
      // Resume existing workout
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutExecutionScreen(workout: incompleteWorkout),
          ),
        );
      }
    } else {
      // Start new workout
      final workout = await ref
          .read(gymProvider)
          .startWorkoutFromRoutine(routine, userId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutExecutionScreen(workout: workout),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges(GymRoutineModel routine) async {
    final updatedRoutine = routine.copyWith(
      routineName: _nameController.text.trim(),
      target: _selectedTarget,
      notes: _notesController.text.trim(),
    );
    await ref.read(gymProvider).updateRoutine(updatedRoutine);
    setState(() => _isEditing = false);
  }

  void _deleteExercise(GymRoutineModel routine, int index) async {
    final exercises = List<ExerciseTemplateModel>.from(routine.exercises);
    exercises.removeAt(index);
    final updatedRoutine = routine.copyWith(exercises: exercises);
    await ref.read(gymProvider).updateRoutine(updatedRoutine);
  }

  @override
  Widget build(BuildContext context) {
    final gymState = ref.watch(gymProvider);
    final routine = gymState.getRoutineById(widget.routineId);

    if (routine == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.gymColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Routine not found')),
      );
    }

    _initializeControllers(routine);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.gymColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          routine.routineName,
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => _handleStart(routine),
            child: Text(
              'START',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(routine);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Routine'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Info Card
            CustomCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Routine name',
                    onChanged: (_) => setState(() => _isEditing = true),
                  ),
                  SizedBox(height: 16.h),
                  _buildTargetDropdown(),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Add notes...',
                    onChanged: (_) => setState(() => _isEditing = true),
                  ),
                  if (_isEditing) ...[
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveChanges(routine),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gymColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Exercises Section
            Text(
              'Exercises',
              style: AppTextStyles.heading2
                  .adaptive(context)
                  .copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),

            if (routine.exercises.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Text(
                    'No exercises added yet',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: routine.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = routine.exercises[index];
                  return _ExerciseListItem(
                    exercise: exercise,
                    onEdit: () => _navigateToEditExercise(routine, index),
                    onDelete: () => _deleteExercise(routine, index),
                  );
                },
              ),

            SizedBox(height: 24.h),

            // Add Exercise Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddExercise(routine),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Exercise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gymColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetDropdown() {
    final targets = RoutineTarget.values.map((t) => t.displayName).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Targets',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkLightGrey
                  : AppColors.lightGrey,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTarget,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: targets.map((target) {
                return DropdownMenuItem(value: target, child: Text(target));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTarget = value;
                    _isEditing = true;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAddExercise(GymRoutineModel routine) async {
    final result = await Navigator.push<ExerciseTemplateModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
    );

    if (result != null) {
      final exercises = List<ExerciseTemplateModel>.from(routine.exercises);
      exercises.add(result);
      final updatedRoutine = routine.copyWith(exercises: exercises);
      await ref.read(gymProvider).updateRoutine(updatedRoutine);
    }
  }

  void _navigateToEditExercise(GymRoutineModel routine, int index) async {
    final exercise = routine.exercises[index];
    final result = await Navigator.push<ExerciseTemplateModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditRoutineExerciseScreen(exercise: exercise),
      ),
    );

    if (result != null) {
      final exercises = List<ExerciseTemplateModel>.from(routine.exercises);
      exercises[index] = result;
      final updatedRoutine = routine.copyWith(exercises: exercises);
      await ref.read(gymProvider).updateRoutine(updatedRoutine);
    }
  }

  void _showDeleteConfirmation(GymRoutineModel routine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text(
          'Are you sure you want to delete "${routine.routineName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gymProvider).deleteRoutine(routine.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
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
}

class _ExerciseListItem extends StatelessWidget {
  final ExerciseTemplateModel exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseListItem({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: AppTextStyles.bodyText
                      .adaptive(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${exercise.plannedSets} Sets',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.grey),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: AppColors.grey),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
