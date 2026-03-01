import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/text_styles.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../models/food_log_model.dart';
import '../providers/food_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AddFoodBottomSheet extends ConsumerStatefulWidget {
  final FoodLogModel? existingLog;

  const AddFoodBottomSheet({super.key, this.existingLog});

  @override
  ConsumerState<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends ConsumerState<AddFoodBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedMealType = 'Breakfast';
  DateTime _selectedTime = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _mealNameController.text = log.mealName;
      _caloriesController.text = log.calories.toString();
      _proteinController.text = log.protein?.toString() ?? '';
      _carbsController.text = log.carbs?.toString() ?? '';
      _fatController.text = log.fat?.toString() ?? '';
      _selectedMealType = log.mealType;
      _selectedTime = log.time;
      _selectedDate = log.time;
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onTimeChanged(TimeOfDay newTime) {
    setState(() {
      _selectedTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        newTime.hour,
        newTime.minute,
      );
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _selectedTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    });
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      final mealName = _mealNameController.text.trim();
      final calories = int.parse(_caloriesController.text.trim());
      final protein = _proteinController.text.trim().isNotEmpty
          ? int.tryParse(_proteinController.text.trim())
          : null;
      final carbs = _carbsController.text.trim().isNotEmpty
          ? int.tryParse(_carbsController.text.trim())
          : null;
      final fat = _fatController.text.trim().isNotEmpty
          ? int.tryParse(_fatController.text.trim())
          : null;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedTime);

      final newLog = FoodLogModel(
        id: widget.existingLog?.id ?? const Uuid().v4(),
        userId: user.id,
        mealName: mealName,
        numberOfServings: 1,
        mealType: _selectedMealType,
        calories: calories,
        time: _selectedTime,
        servingSize: '1 serving',
        date: dateStr,
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

      final foodProv = ref.read(foodProvider);

      if (widget.existingLog != null) {
        await foodProv.updateFoodLog(newLog.id, newLog);
      } else {
        await foodProv.addFoodLog(newLog);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(foodProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                widget.existingLog != null ? 'Edit Log' : 'New Meal',
                style: AppTextStyles.heading1.copyWith(fontSize: 24.sp),
              ),
              SizedBox(height: 24.h),

              CustomTextField(
                controller: _mealNameController,
                label: 'Meal Description',
                hint: 'e.g., Avocado Toast',
                prefixIcon: const Icon(Icons.restaurant_rounded),
                validator: (val) => val?.isEmpty == true ? 'Required' : null,
              ),
              SizedBox(height: 20.h),

              // Calories & Macros in one row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _caloriesController,
                      label: 'Calories',
                      hint: '300',
                      keyboardType: TextInputType.number,
                      contentPadding: EdgeInsets.all(3.w),
                      validator: (val) =>
                          val?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _proteinController,
                      label: 'Protein',
                      hint: 'g',
                      keyboardType: TextInputType.number,
                      contentPadding: EdgeInsets.all(3.w),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _carbsController,
                      label: 'Carbs',
                      hint: 'g',
                      keyboardType: TextInputType.number,
                      contentPadding: EdgeInsets.all(3.w),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _fatController,
                      label: 'Fat',
                      hint: 'g',
                      keyboardType: TextInputType.number,
                      contentPadding: EdgeInsets.all(3.w),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              _buildDropdownField(
                label: 'Meal Type',
                value: _selectedMealType,
                items: _mealTypes,
                onChanged: (val) => setState(() => _selectedMealType = val!),
              ),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(child: _buildDatePickerField()),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTimePickerField()),
                ],
              ),

              SizedBox(height: 32.h),

              CustomButton(
                text: widget.existingLog != null ? 'Update Log' : 'Log Entry',
                onPressed: _handleSave,
                isLoading: isLoading,
                backgroundColor: AppColors.foodColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.expand_more_rounded),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkLightGrey
                    : AppColors.lightGrey,
              ),
            ),
          ),
          items: items
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: AppTextStyles.bodyText),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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

  Widget _buildTimePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Time',
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
          child: CupertinoTimePickerButton(
            initialTime: TimeOfDay.fromDateTime(_selectedTime),
            onTimeChanged: _onTimeChanged,
          ),
        ),
      ],
    );
  }
}
