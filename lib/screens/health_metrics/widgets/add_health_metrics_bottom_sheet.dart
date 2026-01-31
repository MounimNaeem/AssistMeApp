import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../models/health_metrics_model.dart';
import '../providers/health_metrics_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AddHealthMetricsBottomSheet extends ConsumerStatefulWidget {
  final HealthMetricsModel? existingMetrics;

  const AddHealthMetricsBottomSheet({super.key, this.existingMetrics});

  @override
  ConsumerState<AddHealthMetricsBottomSheet> createState() => _AddHealthMetricsBottomSheetState();
}

class _AddHealthMetricsBottomSheetState extends ConsumerState<AddHealthMetricsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bicepsController = TextEditingController();
  final _waistController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _calorieGoalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double? _calculatedBMI;

  @override
  void initState() {
    super.initState();
    if (widget.existingMetrics != null) {
      // Editing existing metrics
      final metrics = widget.existingMetrics!;
      _weightController.text = metrics.weight?.toString() ?? '';
      _heightController.text = metrics.height?.toString() ?? '';
      _bicepsController.text = metrics.biceps?.toString() ?? '';
      _waistController.text = metrics.waist?.toString() ?? '';
      _bodyFatController.text = metrics.bodyFat?.toString() ?? '';
      _muscleMassController.text = metrics.muscleMass?.toString() ?? '';
      _calorieGoalController.text = metrics.calorieGoal?.toString() ?? '';
      _selectedDate = DateTime.parse(metrics.date);
      _calculatedBMI = metrics.bmi;
    } else {
      // Creating new metrics - auto-fill calorie goal from latest metrics
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latestMetrics = ref.read(healthMetricsProvider).latestMetrics;
        if (latestMetrics?.calorieGoal != null) {
          _calorieGoalController.text = latestMetrics!.calorieGoal.toString();
        }
      });
    }

    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
  }

  @override
  void dispose() {
    _weightController.removeListener(_calculateBMI);
    _heightController.removeListener(_calculateBMI);
    _weightController.dispose();
    _heightController.dispose();
    _bicepsController.dispose();
    _waistController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    setState(() {
      _calculatedBMI = HealthMetricsModel.calculateBMI(weight, height);
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      final weight = double.tryParse(_weightController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final biceps = double.tryParse(_bicepsController.text.trim());
      final waist = double.tryParse(_waistController.text.trim());
      final bodyFat = double.tryParse(_bodyFatController.text.trim());
      final muscleMass = double.tryParse(_muscleMassController.text.trim());
      final calorieGoal = int.tryParse(_calorieGoalController.text.trim());
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final newMetrics = HealthMetricsModel(
        id: widget.existingMetrics?.id ?? const Uuid().v4(),
        userId: user.id,
        weight: weight,
        height: height,
        bmi: HealthMetricsModel.calculateBMI(weight, height),
        biceps: biceps,
        waist: waist,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        calorieGoal: calorieGoal,
        date: dateStr,
        createdAt: widget.existingMetrics?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final metricsProvider = ref.read(healthMetricsProvider);

      if (widget.existingMetrics != null) {
        await metricsProvider.updateHealthMetrics(newMetrics.id, newMetrics);
      } else {
        await metricsProvider.addHealthMetrics(newMetrics);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  String? _validateAtLeastOneField(String? value) {
    final weight = _weightController.text.trim();
    final height = _heightController.text.trim();
    final biceps = _bicepsController.text.trim();
    final waist = _waistController.text.trim();
    final bodyFat = _bodyFatController.text.trim();
    final muscleMass = _muscleMassController.text.trim();

    if (weight.isEmpty && height.isEmpty && biceps.isEmpty &&
        waist.isEmpty && bodyFat.isEmpty && muscleMass.isEmpty) {
      return 'Enter at least one measurement';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(healthMetricsProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      padding: EdgeInsets.only(
        left: 28.w,
        right: 28.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                widget.existingMetrics != null ? 'Edit Metrics' : 'New Measurement',
                style: AppTextStyles.heading1.copyWith(fontSize: 24.sp),
              ),
              SizedBox(height: 24.h),

              // Weight & Height row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: '75.5',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.monitor_weight_rounded),
                      validator: _validateAtLeastOneField,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: '175',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.height_rounded),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // BMI Display (auto-calculated)
              if (_calculatedBMI != null)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.healthMetricsColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.healthMetricsColor,
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'BMI: $_calculatedBMI',
                        style: AppTextStyles.bodyText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.healthMetricsColor,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _getBMICategory(_calculatedBMI!),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.healthMetricsColor,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20.h),

              // Body Measurements
              Text(
                'Body Measurements',
                style: AppTextStyles.heading2.copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _bicepsController,
                      label: 'Biceps (cm)',
                      hint: '38.5',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _waistController,
                      label: 'Waist (cm)',
                      hint: '82.0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _bodyFatController,
                      label: 'Body Fat (%)',
                      hint: '15.2',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _muscleMassController,
                      label: 'Muscle Mass (kg)',
                      hint: '42.1',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Calorie Goal
              Text(
                'Nutrition Goal',
                style: AppTextStyles.heading2.copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: _calorieGoalController,
                label: 'Calorie Goal (kcal)',
                hint: '2000',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.local_fire_department_rounded),
                contentPadding: EdgeInsets.all(12.w),
              ),
              SizedBox(height: 20.h),

              // Date Picker
              _buildDatePickerField(),

              SizedBox(height: 32.h),

              CustomButton(
                text: widget.existingMetrics != null ? 'Update Metrics' : 'Save Metrics',
                onPressed: _handleSave,
                isLoading: isLoading,
                backgroundColor: AppColors.healthMetricsColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return '(Underweight)';
    if (bmi < 25) return '(Normal)';
    if (bmi < 30) return '(Overweight)';
    return '(Obese)';
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: CupertinoCalendarPickerButton(
            minimumDateTime: DateTime(2020),
            maximumDateTime: DateTime.now().add(const Duration(days: 1)),
            initialDateTime: _selectedDate,
            onDateTimeChanged: _onDateChanged,
          ),
        ),
      ],
    );
  }
}
