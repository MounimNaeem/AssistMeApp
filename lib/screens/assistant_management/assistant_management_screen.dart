import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../auth/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/assistant_provider.dart';
import 'widgets/add_assistant_bottom_sheet.dart';
import 'widgets/edit_assistant_dialog.dart';

final assistantsProvider = ChangeNotifierProvider((ref) => AssistantProvider());

class AssistantManagementScreen extends ConsumerStatefulWidget {
  const AssistantManagementScreen({super.key});

  @override
  ConsumerState<AssistantManagementScreen> createState() =>
      _AssistantManagementScreenState();
}

class _AssistantManagementScreenState
    extends ConsumerState<AssistantManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      if (user != null) {
        ref.read(assistantsProvider).loadAssistants(user.id);
      }
    });
  }

  String get _clientId => ref.read(authProvider).currentUser!.id;

  @override
  Widget build(BuildContext context) {
    final assistantState = ref.watch(assistantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistant Management'),
        backgroundColor: AppColors.assistantColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: assistantState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : assistantState.assistants.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(24.w),
                  itemCount: assistantState.assistants.length,
                  itemBuilder: (context, index) =>
                      _buildAssistantCard(assistantState.assistants[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssistantSheet,
        label: const Text('Add Assistant'),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: AppColors.assistantColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAssistantCard(UserModel assistant) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.assistantColor.withOpacity(0.1),
            child: Text(
              assistant.name.isNotEmpty
                  ? assistant.name.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.assistantColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assistant.name,
                  style: AppTextStyles.bodyText
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(assistant.email, style: AppTextStyles.caption),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.assistantColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Assistant',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.assistantColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 20.w),
            onPressed: () => _showEditAssistantDialog(assistant),
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20.w),
            onPressed: () => _confirmDelete(assistant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 64.w,
            color: AppColors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No assistants yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.grey),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap + to add your first assistant',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  void _showAddAssistantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAssistantBottomSheet(
        onSubmit: (name, email, password) async {
          return await ref
              .read(assistantsProvider)
              .addAssistant(name, email, password, _clientId);
        },
      ),
    );
  }

  void _showEditAssistantDialog(UserModel assistant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditAssistantDialog(
        assistant: assistant,
        onUpdate: (name, email) async {
          return await ref
              .read(assistantsProvider)
              .updateAssistant(assistant.id, name, email, _clientId);
        },
        onResetPassword: (email) async {
          return await ref.read(assistantsProvider).resetPassword(email);
        },
      ),
    );
  }

  void _confirmDelete(UserModel assistant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assistant?'),
        content: Text(
          'Are you sure you want to delete ${assistant.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(assistantsProvider)
                  .deleteAssistant(assistant.id, _clientId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
