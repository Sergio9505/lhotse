import 'package:flutter/material.dart';

/// Design tokens extracted from Figma.
abstract final class AppColors {
  // Primary
  static const primary = Color(0xFF000000);

  // Backgrounds
  static const background = Color(0xFFE5E2DC);
  static const surface = Color(0xFFD1CEC7);

  // Text
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF8C8A85);
  static const textOnDark = Color(0xFFFFFFFF);

  // Accent
  static const accentMuted = Color(0xFF5A5854);

  // Semantic
  static const danger = Color(0xFFE53E3E);
  static const gold = Color(0xFFDAAC03); // VIP role badge only

  // Borders
  static const border = Color(0x1A000000);
  static const borderLight = Color(0x0D000000);

  // Navigation
  static const navBackground = Color(0xFF000000);
  static const navBorderTop = Color(0x0DFFFFFF);
  static const navShadow = Color(0x66000000);

  // Overlay — warm dark tone for editorial image gradients (projects + detail
  // heroes). Replaces pure black to avoid the "sport story overlay" feel and
  // push toward Sotheby's / Openhouse sepia-luxury.
  static const overlayWarm = Color(0xFF1F1916);
}
