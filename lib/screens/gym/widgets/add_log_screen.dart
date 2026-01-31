import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/gym_workout_model.dart';
import '../models/workout_exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../providers/gym_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  final _logNameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<WorkoutExerciseModel> _exercises = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _logNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _navigateToAddExercise() async {
    final result = await showModalBottomSheet<WorkoutExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddLogExerciseSheet(),
    );

    if (result != null) {
      setState(() => _exercises.add(result));
    }
  }

  void _editExercise(int index) async {
    final result = await showModalBottomSheet<WorkoutExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLogExerciseSheet(exercise: _exercises[index]),
    );

    if (result != null) {
      setState(() => _exercises[index] = result);
    }
  }

  void _handleSave() async {
    if (_logNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a log name')));
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    final user = ref.read(authProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final workout = GymWorkoutModel(
      id: const Uuid().v4(),
      userId: user.id,
      routineId: '',
      routineName: _logNameController.text.trim(),
      date: now,
      startTime: now,
      endTime: now,
      duration: 0,
      notes: _notesController.text.trim(),
      exercises: _exercises,
      completedAt: now,
      isCompleted: true,
    );

    await ref.read(gymProvider).saveWorkout(workout);

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
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
          'Add Log',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Log Info Card
            CustomCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _logNameController,
                    label: 'Name',
                    hint: 'e.g., Morning Workout',
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Add notes...',
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Exercises Section
            Text(
              'Exercises',
              style: AppTextStyles.heading2.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),

            if (_exercises.isEmpty)
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
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return CustomCard(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    onTap: () => _editExercise(index),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.exerciseName,
                                style: AppTextStyles.bodyText.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${ex.sets.length} ${ex.sets.length == 1 ? 'Set' : 'Sets'}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.grey,
                                ),
                              ),
                              if (ex.sets.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Wrap(
                                  spacing: 8.w,
                                  children: ex.sets.map((set) {
                                    return Text(
                                      '${set.weight}${set.weightUnit} × ${set.reps}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.gymColor,
                                        fontSize: 11.sp,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _exercises.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),

            SizedBox(height: 24.h),

            // Add Exercise Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _navigateToAddExercise,
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

            SizedBox(height: 32.h),

            // Save Button
            CustomButton(
              text: 'Save Log',
              onPressed: _handleSave,
              isLoading: _isLoading,
              backgroundColor: AppColors.gymColor,
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for adding exercise with sets
class _AddLogExerciseSheet extends StatefulWidget {
  final WorkoutExerciseModel? exercise;

  const _AddLogExerciseSheet({this.exercise});

  @override
  State<_AddLogExerciseSheet> createState() => _AddLogExerciseSheetState();
}

class _AddLogExerciseSheetState extends State<_AddLogExerciseSheet> {
  final _nameController = TextEditingController();
  final List<ExerciseSetModel> _sets = [];
  String _weightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.exerciseName;
      _sets.addAll(widget.exercise!.sets);
      if (_sets.isNotEmpty) {
        _weightUnit = _sets.first.weightUnit;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addSet() {
    setState(() {
      _sets.add(
        ExerciseSetModel(
          setNumber: _sets.length + 1,
          weight: _sets.isNotEmpty ? _sets.last.weight : 0,
          weightUnit: _weightUnit,
          reps: _sets.isNotEmpty ? _sets.last.reps : 10,
          notes: '',
        ),
      );
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
      // Re-number sets
      for (int i = 0; i < _sets.length; i++) {
        _sets[i] = _sets[i].copyWith(setNumber: i + 1);
      }
    });
  }

  void _updateSet(int index, {double? weight, int? reps}) {
    setState(() {
      _sets[index] = _sets[index].copyWith(
        weight: weight,
        reps: reps,
        weightUnit: _weightUnit,
      );
    });
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter exercise name')),
      );
      return;
    }

    if (_sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one set')),
      );
      return;
    }

    final exercise = WorkoutExerciseModel(
      exerciseName: _nameController.text.trim(),
      completed: true,
      sets: _sets,
    );

    Navigator.pop(context, exercise);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 60.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
                Text(
                  widget.exercise != null ? 'Edit Exercise' : 'Add Exercise',
                  style: AppTextStyles.heading2.copyWith(fontSize: 18.sp),
                ),
                TextButton(
                  onPressed: _handleSave,
                  child: Text(
                    'Save',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.gymColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name
                  CustomTextField(
                    controller: _nameController,
                    label: 'Exercise Name',
                    hint: 'e.g., Bench Press',
                  ),
                  SizedBox(height: 20.h),

                  // Weight Unit Toggle
                  Row(
                    children: [
                      Text(
                        'Weight Unit:',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ToggleButtons(
                        isSelected: [_weightUnit == 'kg', _weightUnit == 'lbs'],
                        onPressed: (index) {
                          setState(() {
                            _weightUnit = index == 0 ? 'kg' : 'lbs';
                            // Update all sets with new unit
                            for (int i = 0; i < _sets.length; i++) {
                              _sets[i] = _sets[i].copyWith(
                                weightUnit: _weightUnit,
                              );
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        selectedColor: Colors.white,
                        fillColor: AppColors.gymColor,
                        constraints: BoxConstraints(
                          minWidth: 50.w,
                          minHeight: 36.h,
                        ),
                        children: const [Text('kg'), Text('lbs')],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Sets Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sets',
                        style: AppTextStyles.heading2.copyWith(fontSize: 16.sp),
                      ),
                      TextButton.icon(
                        onPressed: _addSet,
                        icon: Icon(Icons.add_rounded, size: 20.w),
                        label: const Text('Add Set'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gymColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Sets List
                  if (_sets.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Center(
                        child: Text(
                          'Tap "Add Set" to add sets',
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
                      itemCount: _sets.length,
                      itemBuilder: (context, index) {
                        final set = _sets[index];
                        return _SetRow(
                          setNumber: index + 1,
                          weight: set.weight,
                          reps: set.reps,
                          weightUnit: _weightUnit,
                          onWeightChanged: (value) =>
                              _updateSet(index, weight: value),
                          onRepsChanged: (value) =>
                              _updateSet(index, reps: value),
                          onRemove: () => _removeSet(index),
                        );
                      },
                    ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Individual set row widget
class _SetRow extends StatelessWidget {
  final int setNumber;
  final double weight;
  final int reps;
  final String weightUnit;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;
  final VoidCallback onRemove;

  const _SetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.weightUnit,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // Set number
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.gymColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gymColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Weight input
          Expanded(
            child: _NumberInputField(
              value: weight,
              label: weightUnit,
              onChanged: onWeightChanged,
              isDecimal: true,
            ),
          ),
          SizedBox(width: 8.w),

          // Reps input
          Expanded(
            child: _NumberInputField(
              value: reps.toDouble(),
              label: 'reps',
              onChanged: (value) => onRepsChanged(value.toInt()),
              isDecimal: false,
            ),
          ),
          SizedBox(width: 8.w),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.error,
              size: 24.w,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
          ),
        ],
      ),
    );
  }
}

// Number input field widget
class _NumberInputField extends StatefulWidget {
  final double value;
  final String label;
  final Function(double) onChanged;
  final bool isDecimal;

  const _NumberInputField({
    required this.value,
    required this.label,
    required this.onChanged,
    required this.isDecimal,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isDecimal
          ? (widget.value == widget.value.toInt()
                ? widget.value.toInt().toString()
                : widget.value.toString())
          : widget.value.toInt().toString(),
    );
  }

  @override
  void didUpdateWidget(_NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.isDecimal
          ? (widget.value == widget.value.toInt()
                ? widget.value.toInt().toString()
                : widget.value.toString())
          : widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: widget.isDecimal,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) {
                  widget.onChanged(parsed);
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Text(
              widget.label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
