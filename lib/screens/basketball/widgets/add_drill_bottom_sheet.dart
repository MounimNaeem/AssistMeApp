import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/basketball_drill_model.dart';
import '../basketball_screen.dart';

class AddDrillBottomSheet extends ConsumerStatefulWidget {
  final String category;
  final BasketballDrillModel? existingDrill;

  const AddDrillBottomSheet({
    super.key,
    required this.category,
    this.existingDrill,
  });

  @override
  ConsumerState<AddDrillBottomSheet> createState() =>
      _AddDrillBottomSheetState();
}

class _AddDrillBottomSheetState extends ConsumerState<AddDrillBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _drillNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingDrill != null) {
      final drill = widget.existingDrill!;
      _drillNameController.text = drill.drillName;
      _descriptionController.text = drill.description;
      _videoUrlController.text = drill.videoUrl ?? '';
    }
  }

  @override
  void dispose() {
    _drillNameController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveDrill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      final drill = BasketballDrillModel(
        id: widget.existingDrill?.id ?? const Uuid().v4(),
        userId: user.id,
        createdBy: user.name,
        category: widget.category,
        drillName: _drillNameController.text.trim(),
        description: _descriptionController.text.trim(),
        videoUrl: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        createdAt: widget.existingDrill?.createdAt ?? DateTime.now(),
      );

      if (widget.existingDrill != null) {
        await ref.read(basketballProvider).updateDrill(drill.id, drill);
      } else {
        await ref.read(basketballProvider).addDrill(drill);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving drill: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDrill != null;
    final categoryName = DrillCategory.getDisplayName(widget.category);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.sportsColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.sports_basketball_rounded,
                        color: AppColors.sportsColor,
                        size: 24.w,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Drill' : 'Add New Drill',
                            style: AppTextStyles.heading2
                                .adaptive(context)
                                .copyWith(fontSize: 20.sp),
                          ),
                          Text(
                            categoryName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.sportsColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Drill Name Field
                CustomTextField(
                  controller: _drillNameController,
                  label: 'Drill Name',
                  hint: 'e.g., Mikan Drill, Three-Point Shooting',
                  prefixIcon: const Icon(Icons.label_rounded),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a drill name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                // Description Field
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe the drill steps and objectives',
                  prefixIcon: const Icon(Icons.description_rounded),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                // Video URL Field (Optional)
                CustomTextField(
                  controller: _videoUrlController,
                  label: 'Video Link (Optional)',
                  hint: 'Paste YouTube or video link',
                  prefixIcon: const Icon(Icons.video_library_rounded),
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: 8.h),
                // Helper text
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14.w,
                      color: AppColors.grey,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Video will open in external app when tapped',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                // Save Button
                CustomButton(
                  text: isEditing ? 'Update Drill' : 'Add Drill',
                  onPressed: _isSaving ? null : _saveDrill,
                  isLoading: _isSaving,
                  backgroundColor: AppColors.sportsColor,
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
