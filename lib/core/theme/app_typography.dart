import 'package:flutter/material.dart';

/// Typography tokens — Campton only, role-based naming.
///
/// 12 semantic tokens covering the entire app's editorial system
/// (luxury wealth management). Reach for a token by its role
/// (editorialHero, figureAmount, bodyEmphasis…); residual copyWith is
/// restricted to color / fontStyle / fontSize-residual / letterSpacing
/// when justified by callers.
///
/// Hierarchy: editorialHero 48 → editorialTitle 36 → editorialSubtitle
/// 24 / titleUppercaseLg 24 → titleUppercase 18 / figureAmount 18 /
/// bodyInput 18 → bodyEmphasis 16 → bodyReading 14 → labelUppercaseMd
/// 12 / annotation 12 → labelUppercaseSm 10.
abstract final class AppTypography {
  /// Public so non-token callers (welcome wordmark with strut, animated
  /// hero figures with interpolated fontSize) reference the family
  /// without re-stringing 'Campton'.
  static const fontFamily = 'Campton';

  // ── Semantic ───────────────────────────────────────────────────────────
  // Roles, not shapes. Prefer these for all new code.

  /// Editorial hero — top-level covers. 48pt Light mixed case.
  /// L1 Estrategia, archive covers (ProjectShowcaseCard), project_detail
  /// + news_detail hero, feed_card title.
  static const editorialHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    height: 0.98,
    letterSpacing: -0.5,
  );

  /// Editorial title — interior covers (one level down). 36pt Light mixed.
  /// L2 Estrategia (brand hero), L3 Estrategia (asset/contract hero).
  static const editorialTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: -0.4,
  );

  /// Editorial subtitle / tagline — 24pt Medium mixed case.
  /// brand_detail tagline, second-level statements.
  static const editorialSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: -0.3,
  );

  /// Uppercase title, large — 24pt Medium. project_card (home feed),
  /// large card heros.
  static const titleUppercaseLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Uppercase title — 18pt Medium. Collapsed AppBars, asset rows in L2,
  /// search result cards, brand fallback wordmarks.
  static const titleUppercase = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Financial figure — row-level amounts. 18pt w400 + tabularFigures
  /// for column-stable alignment. Color set per screen.
  static const figureAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Uppercase label, medium — 12pt w500 tracked. Section labels,
  /// sticky headers, CTAs ("DESCARGAR FOLLETO", "VISITAR WEB"),
  /// tab markers.
  static const labelUppercaseMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.5,
  );

  /// Uppercase label, small — 10pt w500 tracked. Brand names, phase chips,
  /// location byline, "PRIVATE", kicker above hero, flag row labels.
  static const labelUppercaseSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.2,
  );

  /// Body input — 18pt Regular. Mixed-case text inputs (search field,
  /// auth fields) one step above bodyReading for primary input prominence.
  /// Drop hint weight to w300 via copyWith.
  static const bodyInput = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.1,
  );

  /// Body emphasis — 16pt Medium. Ledger row title + amount, doc row
  /// names, key-value emphasized values. Heavier than bodyReading for
  /// rows where the value is the read target. Apply tabularFigures via
  /// copyWith for column-stable amounts.
  static const bodyEmphasis = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.1,
  );

  /// Body reading — 14pt Regular, line-height 1.6. Description paragraphs
  /// (project_detail, brand_detail, news body). Color via copyWith.
  static const bodyReading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Annotation — 12pt w400. Taglines, italic annotations, "est." labels.
  /// Apply italic via copyWith(fontStyle) when needed.
  static const annotation = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // ── Legacy (pre-semantic) ──────────────────────────────────────────────
  // Kept alive while home/investments/brands/search and auth/notifications/
  // profile migrate. Do not use in new code.

  @Deprecated('Use editorialHero instead')
  static const displayHero = editorialHero;

  @Deprecated('Use editorialHero (w300 48pt) or editorialTitle (w300 36pt) instead')
  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );

  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.15,
  );

  @Deprecated('Use titleUppercaseLg (24pt caps) or editorialSubtitle (24pt mixed) instead')
  static const headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.48,
  );

  static const headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  @Deprecated('Use titleUppercase (18pt caps) or figureAmount (18pt w400 tabular) instead')
  static const headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  @Deprecated('Use bodyReading instead')
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  @Deprecated('Use annotation instead')
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.36,
  );

  @Deprecated('Use labelUppercaseMd instead')
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  @Deprecated('Use labelUppercaseSm (caps) or annotation (mixed) instead')
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  @Deprecated('Use labelUppercaseSm instead')
  static const captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 8,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
