import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../../widgets/loading_indicator.dart';
import 'providers/study_provider.dart';
import 'models/study_task_model.dart';
import 'widgets/add_study_task_bottom_sheet.dart';

final studyTasksProvider = ChangeNotifierProvider((ref) => StudyProvider());

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyTasksProvider).startListening();
    });
  }

  void _showAddTaskSheet({StudyTaskModel? existingTask}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStudyTaskBottomSheet(existingTask: existingTask),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyTasksProvider);
    final sortedDates = studyState.tasksByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b)); // Sort dates ascending

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Study Tasks',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.studyColor,
        elevation: 0,
      ),
      body: studyState.isLoading && studyState.tasksByDate.isEmpty
          ? const LoadingIndicator(message: 'Loading your tasks...')
          : studyState.tasksByDate.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final tasks = studyState.tasksByDate[date]!;
                // Sort: incomplete first, then completed
                final sortedTasks = [
                  ...tasks.where((t) => !t.completed),
                  ...tasks.where((t) => t.completed),
                ];
                final completedCount = studyState.getCompletedCountForDate(
                  date,
                );
                final totalCount = studyState.getTotalCountForDate(date);

                String displayDate = _getDisplayDate(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 8.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayDate,
                            style: AppTextStyles.heading2
                                .adaptive(context)
                                .copyWith(fontSize: 18.sp),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.studyColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '$completedCount / $totalCount done',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.studyColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...sortedTasks.map(
                      (task) => _StudyTaskCard(
                        task: task,
                        onEdit: () => _showAddTaskSheet(existingTask: task),
                        onDelete: () => _confirmDelete(task),
                        onToggle: () =>
                            ref.read(studyTasksProvider).toggleCompletion(task),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(),
        label: Text(
          'Add Task',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: AppColors.studyColor,
        elevation: 4,
      ),
    );
  }

  String _getDisplayDate(String date) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));
    final tomorrow = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 1)));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    if (date == tomorrow) return 'Tomorrow';
    try {
      return DateFormat('EEEE, MMM d').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppColors.studyColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 64.w,
              color: AppColors.studyColor,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No study tasks yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
          ),
          SizedBox(height: 8.h),
          Text('Tap + to add your first task', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  void _confirmDelete(StudyTaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(studyTasksProvider).deleteTask(task.id);
              if (mounted) Navigator.pop(ctx);
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

class _StudyTaskCard extends StatefulWidget {
  final StudyTaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _StudyTaskCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_StudyTaskCard> createState() => _StudyTaskCardState();
}

class _StudyTaskCardState extends State<_StudyTaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final hasDetails = task.hasDetails;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: hasDetails
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: task.completed,
                activeColor: AppColors.studyColor,
                onChanged: (_) => widget.onToggle(),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName,
                      style: AppTextStyles.bodyText
                          .adaptive(context)
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.completed
                                ? AppColors.grey
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkOnBackground
                                      : AppColors.onBackground),
                          ),
                    ),
                    if (hasDetails) ...[
                      SizedBox(height: 8.h),
                      _buildDetailsSection(),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: AppColors.grey,
                  size: 20.w,
                ),
                onPressed: widget.onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                  size: 20.w,
                ),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final task = widget.task;

    if (_isExpanded && task.detailsJson.isNotEmpty) {
      // Show full rich text content
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuillContent(),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Text(
              'Show less',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.studyColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    } else {
      // Show collapsed plain text (max 3 lines)
      final plainText = task.detailsPlainText;
      final lines = plainText.split('\n');
      final needsExpansion = lines.length > 3 || plainText.length > 150;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plainText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey,
              decoration: task.completed ? TextDecoration.lineThrough : null,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (needsExpansion) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Text(
                'Show more',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.studyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildQuillContent() {
    final task = widget.task;

    try {
      final deltaJson = jsonDecode(task.detailsJson);
      final document = Document.fromJson(deltaJson);
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return IgnorePointer(
        child: QuillEditor.basic(
          controller: controller,
          config: QuillEditorConfig(
            showCursor: false,
            padding: EdgeInsets.zero,
          ),
        ),
      );
    } catch (_) {
      // Fallback to plain text if JSON parsing fails
      return Text(
        task.detailsPlainText,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey,
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      );
    }
  }
}
