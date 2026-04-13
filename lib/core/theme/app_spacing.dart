import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: 24);
  static const cardPadding = EdgeInsets.all(16);
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;

  static final cardRadius = BorderRadius.zero;
  static final buttonRadius = BorderRadius.zero;
  static final chipRadius = BorderRadius.zero;
}
