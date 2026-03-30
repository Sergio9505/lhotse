import 'package:flutter/material.dart';

/// Design tokens extracted from Figma.
abstract final class AppColors {
  // Primary
  static const primary = Color(0xFF1A1E2F);

  // Backgrounds
  static const background = Color(0xFFE5E2DC);
  static const surface = Color(0xFFD1CEC7);

  // Text
  static const textPrimary = Color(0xFF1A1E2F);
  static const textSecondary = Color(0xFF8C8A85);
  static const textOnDark = Color(0xFFFFFFFF);

  // Accent
  static const accentMuted = Color(0xFF5A5854);

  // Semantic
  static const danger = Color(0xFF7F1D1D);

  // Borders
  static const border = Color(0x1A1A1E2F);
  static const borderLight = Color(0x0D1A1E2F);

  // Navigation
  static const navBackground = Color(0xFF1A1E2F);
  static const navBorderTop = Color(0x0DFFFFFF);
  static const navShadow = Color(0x66000000);
}
