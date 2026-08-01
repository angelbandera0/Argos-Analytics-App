import 'package:flutter/material.dart';

/// Global color palette for Argos Analytics.
/// Extracted from the brand system: Plus Jakarta Sans / coral & ink palette.
abstract class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFE07B6C); // coral
  static const Color ink = Color(0xFF1C1C1F); // near black
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7F7);

  // Surfaces
  static const Color surface = white;
  static const Color surfaceMuted = Color(0xFFF3F3F4);
  static const Color surfaceSunken = Color(0xFFF0F0F1);
  static const Color border = Color(0xFFE7E7E9);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1F);
  static const Color textSecondary = Color(0xFF6F6F76);
  static const Color textMuted = Color(0xFFA1A1A8);
  static const Color textOnPrimary = white;
  static const Color textOnInk = white;

  // Status / accents used across tags & progress
  static const Color statusTodo = Color(0xFF9C9CA3);
  static const Color statusInProgress = Color(0xFF5B8DEF);
  static const Color statusReview = Color(0xFFE8A33D);
  static const Color statusDone = Color(0xFF4CAF7D);

  static const Color tagDesign = Color(0xFFEFE4FB);
  static const Color tagDesignText = Color(0xFF8A4FD1);
  static const Color tagWeb = Color(0xFFE3F0FE);
  static const Color tagWebText = Color(0xFF3E7BC4);
  static const Color tagMobile = Color(0xFFFDE8E3);
  static const Color tagMobileText = Color(0xFFCB6752);
  static const Color tagDev = Color(0xFFE7F6EC);
  static const Color tagDevText = Color(0xFF3E9160);
  static const Color tagMarketing = Color(0xFFFFF3D6);
  static const Color tagMarketingText = Color(0xFFB5842A);

  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF4CAF7D);

  static const List<Color> avatarPalette = [
    Color(0xFFE07B6C),
    Color(0xFF5B8DEF),
    Color(0xFFE8A33D),
    Color(0xFF4CAF7D),
    Color(0xFF8A4FD1),
  ];
}
