import 'package:flutter/material.dart';

/// Typography tokens — Campton only.
abstract final class AppTypography {
  static const _fontFamily = 'Campton';

  // Display
  //
  // `displayHero` — cover-of-magazine treatment for editorial archive titles
  // (ProjectShowcaseCard, LhotseNewsCard, and their detail hero titles). Light
  // weight + XL size + tight line-height is the signature of minimal luxury
  // contemporary (Céline, Jil Sander, Totême). Used ONLY in archive / detail
  // hero contexts; everything else stays with the established scale.
  static const displayHero = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    height: 0.95,
    letterSpacing: -0.5,
  );

  static const displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );

  static const displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.15,
  );

  // Headings
  static const headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.48,
  );

  static const headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  static const headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.36,
  );

  // Labels (uppercase)
  static const labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Caption
  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const captionSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 8,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
