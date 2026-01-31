import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/gym_routine_model.dart';
import '../models/exercise_template_model.dart';
import '../providers/gym_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_exercise_screen.dart';

class AddRoutineScreen extends ConsumerStatefulWidget {
  const AddRoutineScreen({super.key});

  @override
  ConsumerState<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends ConsumerState<AddRoutineScreen> {
  final _routineNameController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedTarget = 'Latest';
  final List<ExerciseTemplateModel> _exercises = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _routineNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _navigateToAddExercise() async {
    final result = await Navigator.push<ExerciseTemplateModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
    );

    if (result != null) {
      setState(() => _exercises.add(result));
    }
  }

  void _handleSave() async {
    if (_routineNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine name')),
      );
      return;
    }

    final user = ref.read(authProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final newRoutine = GymRoutineModel(
      id: const Uuid().v4(),
      routineName: _routineNameController.text.trim(),
      target: _selectedTarget,
      notes: _notesController.text.trim(),
      createdBy: user.id,
      exercises: _exercises,
      createdAt: DateTime.now(),
    );

    await ref.read(gymProvider).addRoutine(newRoutine);

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
        title: Text('New Routine', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
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
                    controller: _routineNameController,
                    label: 'Name',
                    hint: 'e.g., Upper Body',
                  ),
                  SizedBox(height: 16.h),
                  _buildTargetDropdown(),
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
                    style: AppTextStyles.caption.copyWith(color: AppColors.grey),
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                '${ex.plannedSets} Sets',
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.grey),
                          onPressed: () => setState(() => _exercises.removeAt(index)),
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Save Button
            CustomButton(
              text: 'Save Routine',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTarget,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: targets.map((target) {
                return DropdownMenuItem(
                  value: target,
                  child: Text(target),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTarget = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
