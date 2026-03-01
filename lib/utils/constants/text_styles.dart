import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle get heading1 => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.onBackground,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    letterSpacing: -0.3,
  );

  static TextStyle get bodyText => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
    height: 1.5,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.grey,
  );

  static TextStyle get button => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.5,
  );
}

/// Extension to adapt text styles to the current theme brightness.
/// Usage: AppTextStyles.heading1.adaptive(context)
extension AdaptiveTextStyle on TextStyle {
  TextStyle adaptive(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return this;

    // Map light text colors to dark equivalents
    if (color == AppColors.onBackground || color == AppColors.onSurface) {
      return copyWith(color: AppColors.darkOnBackground);
    }
    if (color == AppColors.grey) {
      return copyWith(color: AppColors.darkGrey);
    }
    return this;
  }
}
