import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/exercise_template_model.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _nameController = TextEditingController();
  String? _selectedCategory;
  String _selectedExerciseType = ExerciseType.strengthWeightReps.displayName;
  String _selectedSingleLimb = SingleLimbOption.no.displayName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter exercise name')),
      );
      return;
    }

    final exercise = ExerciseTemplateModel(
      exerciseName: _nameController.text.trim(),
      plannedSets: 3, // Default sets
      warmUpSets: 0,
      category: _selectedCategory,
      exerciseType: _selectedExerciseType,
      singleLimbOption: _selectedSingleLimb,
      notes: '',
    );

    Navigator.pop(context, exercise);
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
          'Add Exercise',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: Text(
              'SAVE',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
            // Name Field
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Exercise name',
            ),
            SizedBox(height: 20.h),

            // Category Dropdown
            _buildDropdown(
              label: 'Category',
              value: _selectedCategory,
              hint: 'Select category',
              items: ExerciseCategory.values.map((c) => c.displayName).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            SizedBox(height: 20.h),

            // Exercise Type Dropdown
            _buildExerciseTypeDropdown(),
            SizedBox(height: 20.h),

            // Single Leg/Arm Dropdown
            _buildDropdown(
              label: 'Single Leg / Single Arm',
              value: _selectedSingleLimb,
              items: SingleLimbOption.values.map((s) => s.displayName).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSingleLimb = value);
                }
              },
            ),
            if (_selectedSingleLimb != SingleLimbOption.no.displayName)
              Padding(
                padding: EdgeInsets.only(top: 8.h, left: 4.w),
                child: Text(
                  'Count weight twice in statistics',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                ),
              ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    String? value,
    String? hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: hint != null ? Text(hint, style: AppTextStyles.bodyText.copyWith(color: AppColors.grey)) : null,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Exercise Type',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedExerciseType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: ExerciseType.values.map((type) {
                return DropdownMenuItem(
                  value: type.displayName,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.displayName),
                      Text(
                        'Examples: ${type.examples}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedExerciseType = value);
                }
              },
              selectedItemBuilder: (context) {
                return ExerciseType.values.map((type) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(type.displayName),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }
}
