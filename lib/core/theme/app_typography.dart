import 'package:flutter/material.dart';

/// Typography tokens — Campton only, role-based naming.
///
/// 18 semantic tokens covering the entire app's editorial system
/// (luxury wealth management). Reach for a token by its role;
/// residual copyWith is restricted to color / fontStyle only.
///
/// Editorial scale:   editorialHero 48 → editorialTitle 36 → editorialSubtitle 24
/// Title scale:       titleUppercaseLg 24 → titleUppercase 18
/// Figure scale:      figureHero 40 → figureRow 22 → figureAmount 18 → figureCurrency 14
/// Body scale:        bodyInput 18 → bodyEmphasis 16 → bodyReading 14
/// Label scale:       labelUppercaseMd 12 → annotation 12 → labelUppercaseSm 10
/// Micro scale:       metaUppercase 12 → metaCaption 12 → badgePill 9
abstract final class AppTypography {
  /// Public so non-token callers (welcome wordmark with strut, animated
  /// hero figures with interpolated fontSize) reference the family
  /// without re-stringing 'Campton'.
  static const fontFamily = 'Campton';

  // ── Semantic ───────────────────────────────────────────────────────────
  // Roles, not shapes. Prefer these for all new code.

  /// Editorial hero — top-level covers. 48pt Light mixed case.
  /// L1 Estrategia, project_detail + news_detail hero, feed_card title.
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

  /// Figure hero — full-screen detail header amount. 40pt w400 tabular.
  /// L3 investment detail screens (compraDirecta / coinversion / completed).
  static const figureHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w400,
    height: 1.1,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Figure row — row-level capital amounts. 22pt w500 tabular.
  /// Investment row widgets (PurchaseRow, CoinvestmentRow, RentaFijaRow).
  static const figureRow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Financial figure — ledger-level amounts. 18pt w400 + tabularFigures
  /// for column-stable alignment. Color set per screen.
  static const figureAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Figure currency — paired € / currency glyph. 14pt w400.
  /// Sits beside figureRow or figureAmount; muted color via copyWith.
  static const figureCurrency = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -0.1,
  );

  /// Uppercase label, medium — 12pt w500 tracked. Section labels,
  /// sticky headers, CTAs ("DESCARGAR FOLLETO", "VISITAR WEB"),
  /// tab markers, filter chips.
  static const labelUppercaseMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.8,
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
  /// names, key-value emphasized values, primary tab navigation
  /// (LhotseFilterTab editorial mode). Heavier than bodyReading for
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

  /// Meta uppercase — 12pt w500, no tracking. Investment row meta lines
  /// (yield, reval, payment frequency, phase). Same size as annotation
  /// but uppercase w500 with tracking reset — distinct from labelUppercaseSm
  /// which is 10pt for brand bylines / chips.
  static const metaUppercase = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Meta caption — 12pt w400 sentence-case. Labels beneath figures
  /// ("Valor de compra", metric column labels). Same size as annotation
  /// but sentence-case w400 without italic.
  static const metaCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Badge pill — 9pt w500 uppercase tight tracking. Status pills:
  /// role badge (INVERSOR / VIEWER), KYC status, security status.
  static const badgePill = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.8,
  );

}
