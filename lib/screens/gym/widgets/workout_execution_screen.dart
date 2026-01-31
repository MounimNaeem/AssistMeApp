import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/gym_workout_model.dart';
import '../models/workout_exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../providers/gym_provider.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  final GymWorkoutModel workout;

  const WorkoutExecutionScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  late GymWorkoutModel _workout;
  final _notesController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Keep existing start time if workout was already started, otherwise use current time
    _workout = widget.workout.isCompleted
        ? widget.workout
        : widget.workout.copyWith(startTime: widget.workout.startTime);
    _notesController.text = _workout.notes;
    _nameController.text = _workout.routineName;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() => _workout = _workout.copyWith(date: newDate));
    _autoSave();
  }

  void _onStartTimeChanged(TimeOfDay newTime) {
    final newStartTime = DateTime(
      _workout.startTime.year,
      _workout.startTime.month,
      _workout.startTime.day,
      newTime.hour,
      newTime.minute,
    );
    setState(() => _workout = _workout.copyWith(startTime: newStartTime));
    _autoSave();
  }

  void _onEndTimeChanged(TimeOfDay newTime) {
    final baseDate = _workout.endTime ?? DateTime.now();
    final newEndTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      newTime.hour,
      newTime.minute,
    );
    setState(() => _workout = _workout.copyWith(endTime: newEndTime));
    _autoSave();
  }

  void _handleEnd() async {
    final endTime = DateTime.now();
    final duration = endTime.difference(_workout.startTime).inMinutes;

    // Complete the workout - update local state FIRST to prevent PopScope from overwriting
    final completedWorkout = _workout.copyWith(
      endTime: endTime,
      duration: duration,
      completedAt: endTime,
      notes: _notesController.text.trim(),
      routineName: _nameController.text.trim(),
      isCompleted: true,
    );

    // Update local state so PopScope saves the completed version
    setState(() => _workout = completedWorkout);

    await ref.read(gymProvider).saveWorkout(completedWorkout);

    // Navigate back after saving
    if (mounted) Navigator.pop(context);
  }

  void _deleteExercise(int index) {
    final newExercises = List<WorkoutExerciseModel>.from(_workout.exercises);
    newExercises.removeAt(index);
    setState(() => _workout = _workout.copyWith(exercises: newExercises));
    _autoSave();
  }

  void _deleteSet(int exIndex, int setIndex) {
    final exercise = _workout.exercises[exIndex];
    final newSets = List<ExerciseSetModel>.from(exercise.sets);
    newSets.removeAt(setIndex);
    // Renumber the sets
    for (int i = 0; i < newSets.length; i++) {
      newSets[i] = newSets[i].copyWith(setNumber: i + 1);
    }
    _updateExercise(exIndex, exercise.copyWith(sets: newSets));
  }

  Future<void> _autoSave() async {
    // Auto-save changes to database
    await ref
        .read(gymProvider)
        .saveWorkout(
          _workout.copyWith(
            notes: _notesController.text.trim(),
            routineName: _nameController.text.trim(),
          ),
        );
  }

  void _handleSave() async {
    final endTime = _workout.endTime ?? DateTime.now();
    final duration = endTime.difference(_workout.startTime).inMinutes;
    final finalWorkout = _workout.copyWith(
      endTime: endTime,
      duration: duration,
      completedAt: endTime,
      notes: _notesController.text.trim(),
      routineName: _nameController.text.trim(),
      isCompleted: true,
    );

    // Update local state so PopScope saves the completed version
    setState(() => _workout = finalWorkout);

    await ref.read(gymProvider).saveWorkout(finalWorkout);
    if (mounted) Navigator.pop(context);
  }

  void _updateExercise(int index, WorkoutExerciseModel updatedEx) {
    final newExercises = List<WorkoutExerciseModel>.from(_workout.exercises);
    newExercises[index] = updatedEx;
    setState(() => _workout = _workout.copyWith(exercises: newExercises));
    _autoSave();
  }

  @override
  Widget build(BuildContext context) {
    // Show END button only for incomplete workouts
    final isWorkoutCompleted = _workout.isCompleted;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _autoSave();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(DateFormat('MMM d').format(_workout.date)),
          elevation: 0,
          backgroundColor: AppColors.gymColor,
          foregroundColor: Colors.white,
          actions: [
            if (!isWorkoutCompleted)
              TextButton(
                onPressed: _handleEnd,
                child: Text(
                  'END',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              CustomTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Workout name',
                onChanged: (val) {
                  setState(
                    () => _workout = _workout.copyWith(routineName: val),
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Date picker
              _buildDatePickerField(),
              SizedBox(height: 16.h),

              // Start Time and End Time in a row
              Row(
                children: [
                  Expanded(child: _buildStartTimePickerField()),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildEndTimePickerField()),
                ],
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Notes',
                  hintStyle: AppTextStyles.bodyText.copyWith(
                    color: AppColors.grey,
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.all(12.w),
                ),
              ),
              Divider(height: 48.h, thickness: 1, color: AppColors.lightGrey),

              ..._workout.exercises
                  .asMap()
                  .entries
                  .map((entry) => _buildExerciseItem(entry.key, entry.value))
                  .toList(),

              SizedBox(height: 40.h),
              CustomButton(
                text: _workout.isCompleted ? 'Update Workout' : 'Save Workout',
                onPressed: _handleSave,
                isLoading: ref.watch(gymProvider).isLoading,
                backgroundColor: AppColors.gymColor,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Date',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(surface: Colors.transparent),
            ),
            child: CupertinoCalendarPickerButton(
              minimumDateTime: DateTime.now().subtract(
                const Duration(days: 365),
              ),
              maximumDateTime: DateTime.now().add(const Duration(days: 365)),
              initialDateTime: _workout.date,
              onDateTimeChanged: _onDateChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartTimePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Start Time',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(surface: Colors.transparent),
            ),
            child: CupertinoTimePickerButton(
              initialTime: TimeOfDay.fromDateTime(_workout.startTime),
              onTimeChanged: _onStartTimeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndTimePickerField() {
    final hasEndTime = _workout.endTime != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'End Time',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: hasEndTime
              ? Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(surface: Colors.transparent),
                  ),
                  child: CupertinoTimePickerButton(
                    initialTime: TimeOfDay.fromDateTime(_workout.endTime!),
                    onTimeChanged: _onEndTimeChanged,
                  ),
                )
              : GestureDetector(
                  onTap: _handleEnd,
                  child: Text(
                    'Tap END to set',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(int index, WorkoutExerciseModel ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ex.exerciseName,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 22.sp,
                color: AppColors.primary,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteExercise(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Exercise'),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            SizedBox(width: 30.w),
            Expanded(
              child: Center(
                child: Text(
                  'kg',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Reps',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Notes',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 30.w),
          ],
        ),
        ...ex.sets
            .asMap()
            .entries
            .map(
              (setEntry) =>
                  _buildSetRow(index, ex, setEntry.key, setEntry.value),
            )
            .toList(),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: () {
            final newSets = List<ExerciseSetModel>.from(ex.sets);
            newSets.add(
              ExerciseSetModel(
                setNumber: newSets.length + 1,
                weight: 0,
                weightUnit: 'kg',
                reps: 0,
                notes: '',
              ),
            );
            _updateExercise(index, ex.copyWith(sets: newSets));
          },
          child: Text(
            'Add Set',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Divider(height: 40.h),
      ],
    );
  }

  Widget _buildSetRow(
    int exIndex,
    WorkoutExerciseModel ex,
    int setIndex,
    ExerciseSetModel set,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.grey),
            ),
            child: Center(
              child: Text(
                '${set.setNumber}',
                style: AppTextStyles.caption.copyWith(fontSize: 10.sp),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildInputBox(
              set.weight > 0
                  ? (set.weight % 1 == 0
                        ? '${set.weight.toInt()}'
                        : '${set.weight}')
                  : '0',
              (v) {
                final val = double.tryParse(v) ?? 0;
                final newSets = List<ExerciseSetModel>.from(ex.sets);
                newSets[setIndex] = set.copyWith(weight: val);
                _updateExercise(exIndex, ex.copyWith(sets: newSets));
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildInputBox('${set.reps > 0 ? set.reps : 0}', (v) {
              final val = int.tryParse(v) ?? 0;
              final newSets = List<ExerciseSetModel>.from(ex.sets);
              newSets[setIndex] = set.copyWith(reps: val);
              _updateExercise(exIndex, ex.copyWith(sets: newSets));
            }),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildInputBox(set.notes, (v) {
              final newSets = List<ExerciseSetModel>.from(ex.sets);
              newSets[setIndex] = set.copyWith(notes: v);
              _updateExercise(exIndex, ex.copyWith(sets: newSets));
            }),
          ),
          SizedBox(width: 8.w),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.grey,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'delete') {
                _deleteSet(exIndex, setIndex);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete Set')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(
    String text,
    Function(String) onChanged, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _InputBox(
      text: text,
      onChanged: onChanged,
      keyboardType: keyboardType,
    );
  }
}

class _InputBox extends StatefulWidget {
  final String text;
  final Function(String) onChanged;
  final TextInputType keyboardType;

  const _InputBox({
    required this.text,
    required this.onChanged,
    required this.keyboardType,
  });

  @override
  State<_InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<_InputBox> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(_InputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_isFocused) {
      _controller.text = widget.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
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
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Focus(
        onFocusChange: (focused) => _isFocused = focused,
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          keyboardType: widget.keyboardType,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: AppTextStyles.bodyText.copyWith(fontSize: 14.sp),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
