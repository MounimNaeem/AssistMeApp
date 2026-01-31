import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_styles.dart';
import '../../utils/routes/app_router.dart';
import '../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.onBackground,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(user?.name.substring(0,1).toUpperCase() ?? 'U', style: AppTextStyles.heading1.copyWith(color: AppColors.primary)),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'User Name', style: AppTextStyles.heading2),
                        Text(user?.email ?? 'user@example.com', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.lock_outline_rounded,
                title: 'Update Password',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, AppRouter.updatePassword),
              ),
              const Divider(indent: 56),
              _buildSettingItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                color: AppColors.warning,
                onTap: () {},
              ),
              const Divider(indent: 56),
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                color: AppColors.info,
                onTap: () {},
              ),
            ]),
            SizedBox(height: 24.h),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                color: AppColors.error,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required VoidCallback onTap, required Color color}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
        child: Icon(icon, color: color, size: 22.w),
      ),
      title: Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
    );
  }
}
