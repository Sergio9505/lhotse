import 'package:flutter/material.dart';

/// Typography tokens — Campton only, role-based naming.
///
/// 23 semantic tokens covering the entire app's editorial system
/// (luxury wealth management). Reach for a token by its role.
///
/// CONTRACT: `.copyWith` is restricted to `color` and `fontStyle` only.
/// Any other property override (fontSize, fontWeight, letterSpacing,
/// height) is a signal to either use an existing token or add one here.
///
/// Editorial scale:   editorialHero 48 → editorialTitle 36 → editorialSubtitle 24
/// Title scale:       titleUppercaseLg 24 → titleUppercase 18
/// Figure scale:      figureHero 40 → figureRow 22 → figureAmount 18 → figureCurrency 14
/// Body scale:        bodyInput 18 → bodyEmphasis 16 → bodyRow 16 → bodyReading 14
/// Label scale:       labelUppercaseMd 12 → sectionLabel 12 → annotation 12 → annotationParagraph 12 → labelUppercaseSm 10 → wordmarkByline 10
/// Micro scale:       metaUppercase 12 → metaCaption 12 → badgePill 9 → badgeMicro 8
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

  /// Section label — 12pt w400 tracked. Quiet section headers that read as
  /// passive organizers (vs labelUppercaseMd w500 for active control labels).
  /// Used by LhotseSectionLabel and any inline section header inside a Row.
  static const sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 1.8,
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

  /// Wordmark byline — uppercase brand identifier in catalog cards and detail
  /// screens. 10pt w500 ls 1.5. Used in project_card, project_showcase_card,
  /// lhotse_news_card, brand_detail, asset_detail, project_detail, news_detail,
  /// login, and search results. Wider tracking than labelUppercaseSm (1.2)
  /// reinforces the identity read over descriptive meta.
  static const wordmarkByline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.5,
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

  /// Body row — 16pt Regular. Row primary text in calm read contexts (search
  /// result rows, key-value lists) where the label is informational rather
  /// than the primary value target. Lighter weight than bodyEmphasis (w500).
  static const bodyRow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
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

  /// Annotation — 12pt w400. Short taglines, inline annotations, "est." labels.
  /// Apply italic via copyWith(fontStyle) when needed. For multi-line italic
  /// decks use annotationParagraph (height 1.6).
  static const annotation = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  /// Annotation paragraph — 12pt w400, line-height 1.6. Multi-line italic deck
  /// in editorial cards (catalog cards, detail kickers). Same spec as annotation
  /// but taller line-height for comfortable paragraph reading.
  static const annotationParagraph = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.1,
  );

  /// Meta uppercase — 12pt w500, no tracking. Investment row meta lines
  /// (yield, reval, payment frequency, phase), trending chips, brand
  /// initials fallback. Same size as annotation but w500 — case (upper or
  /// mixed) is decided at call site, not by the token.
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

  /// Badge micro — 8pt w500 uppercase. Compact card bylines
  /// (LhotseNewsCard.compact) and notification count pills.
  static const badgeMicro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 8,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.2,
  );

}
