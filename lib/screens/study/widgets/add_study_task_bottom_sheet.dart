import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/study_task_model.dart';
import '../study_screen.dart';

class AddStudyTaskBottomSheet extends ConsumerStatefulWidget {
  final StudyTaskModel? existingTask;

  const AddStudyTaskBottomSheet({super.key, this.existingTask});

  @override
  ConsumerState<AddStudyTaskBottomSheet> createState() =>
      _AddStudyTaskBottomSheetState();
}

class _AddStudyTaskBottomSheetState
    extends ConsumerState<AddStudyTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  late QuillController _quillController;

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initQuillController();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _taskNameController.text = task.taskName;
      try {
        _selectedDate = DateTime.parse(task.date);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    }
  }

  void _initQuillController() {
    if (widget.existingTask != null &&
        widget.existingTask!.detailsJson.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(widget.existingTask!.detailsJson);
        _quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.studyColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = ref.read(authProvider).currentUser;
      if (user == null) {
        setState(() => _isSaving = false);
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Get Quill content
      final deltaJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );
      final plainText = _quillController.document.toPlainText().trim();

      final task = StudyTaskModel(
        id: widget.existingTask?.id ?? const Uuid().v4(),
        userId: user.id,
        taskName: _taskNameController.text.trim(),
        detailsJson: plainText.isEmpty ? '' : deltaJson,
        detailsPlainText: plainText,
        completed: widget.existingTask?.completed ?? false,
        date: dateStr,
        createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
      );

      final studyProv = ref.read(studyTasksProvider);

      if (widget.existingTask != null) {
        await studyProv.updateTask(task.id, task);
      } else {
        await studyProv.addTask(task);
      }

      setState(() => _isSaving = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
                widget.existingTask != null ? 'Edit Task' : 'New Study Task',
                style: AppTextStyles.heading1.copyWith(fontSize: 24.sp),
              ),
              SizedBox(height: 24.h),
              CustomTextField(
                controller: _taskNameController,
                label: 'Task Name',
                hint: 'e.g., Complete Math Assignment',
                prefixIcon: const Icon(Icons.task_alt_rounded),
                validator: (val) => val?.isEmpty == true ? 'Required' : null,
              ),
              SizedBox(height: 20.h),
              _buildQuillEditor(),
              SizedBox(height: 20.h),
              _buildDatePickerField(),
              SizedBox(height: 32.h),
              CustomButton(
                text: widget.existingTask != null ? 'Update Task' : 'Add Task',
                onPressed: _handleSave,
                isLoading: _isSaving,
                backgroundColor: AppColors.studyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuillEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Details (Optional)',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withOpacity(0.7)
                  : AppColors.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
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
          child: Column(
            children: [
              // Toolbar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkElevated
                      : AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                ),
                child: QuillSimpleToolbar(
                  controller: _quillController,
                  config: QuillSimpleToolbarConfig(
                    showAlignmentButtons: false,
                    showBackgroundColorButton: false,
                    showCenterAlignment: false,
                    showClearFormat: false,
                    showCodeBlock: false,
                    showColorButton: false,
                    showDirection: false,
                    showDividers: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showHeaderStyle: false,
                    showIndent: false,
                    showInlineCode: false,
                    showJustifyAlignment: false,
                    showLeftAlignment: false,
                    showLink: false,
                    showQuote: false,
                    showRightAlignment: false,
                    showSearchButton: false,
                    showSmallButton: false,
                    showStrikeThrough: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showUndo: false,
                    showRedo: false,
                    showListCheck: true,
                    showListBullets: true,
                    showListNumbers: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkLightGrey
                    : AppColors.lightGrey,
              ),
              // Editor
              Container(
                height: 150.h,
                padding: EdgeInsets.all(12.w),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: QuillEditorConfig(
                    placeholder: 'Add details, bullet points, subtasks...',
                    padding: EdgeInsets.zero,
                    expands: true,
                  ),
                ),
              ),
            ],
          ),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnBackground.withOpacity(0.7)
                  : AppColors.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.studyColor,
                  size: 20.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: AppTextStyles.bodyText.adaptive(context),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.grey,
                  size: 24.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
