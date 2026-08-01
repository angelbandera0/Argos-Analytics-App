import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography scale using Plus Jakarta Sans.
abstract class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayLarge = _base(size: 40, weight: FontWeight.w700, height: 1.1);
  static TextStyle h1 = _base(size: 28, weight: FontWeight.w700, height: 1.2);
  static TextStyle h2 = _base(size: 22, weight: FontWeight.w700, height: 1.25);
  static TextStyle h3 = _base(size: 18, weight: FontWeight.w600, height: 1.3);

  static TextStyle bodyLarge = _base(size: 16, weight: FontWeight.w500);
  static TextStyle bodyMedium = _base(size: 14, weight: FontWeight.w500);
  static TextStyle bodySmall = _base(size: 13, weight: FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle label = _base(size: 12, weight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.4);
  static TextStyle caption = _base(size: 11, weight: FontWeight.w500, color: AppColors.textMuted);

  static TextStyle button = _base(size: 14, weight: FontWeight.w600, color: AppColors.textOnPrimary);

  static TextStyle overline = _base(
    size: 12,
    weight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 1.6,
  );
}
