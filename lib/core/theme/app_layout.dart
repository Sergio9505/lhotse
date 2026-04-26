import 'app_spacing.dart';

/// Spacing tokens compartidos por los heros editoriales del flujo Strategy
/// (`InvestmentsScreen` L1 + `BrandInvestmentsScreen` L2). La regla central:
/// `expandedHeight` se DERIVA de la tipografía. Hardcodear `maxExtent` con un
/// valor que no encaje con el tamaño del título y del amount produce huecos
/// vacíos dentro del hero — se considera bug.
abstract final class HeroLayout {
  /// Inset arriba del chrome row (status bar buffer; `topPadding` se suma
  /// fuera del token, en el call site).
  static const chromeTopInset = AppSpacing.md;

  /// Altura del chrome row (logo+bell en L1, back button en L2).
  static const chromeRowHeight = 44.0;

  /// Premium breathing entre chrome row y editorial title.
  static const aboveTitle = 42.0;

  /// Gap entre title bottom y amount top.
  static const titleAmountGap = 20.0;

  /// Breathing entre amount bottom y hero bottom.
  static const belowAmount = 34.0;

  /// `minExtent` del hero — chrome buffer cuando la sliver está colapsada.
  /// `topPadding` se suma fuera del token.
  static const collapsedHeight = 80.0;

  /// Posición Y del amount cuando el hero está colapsado, relativa a
  /// `topPadding`.
  static const collapsedAmountY = 28.0;

  /// Altura expandida del hero en función de la tipografía. Llamantes:
  /// `maxExtent = topPadding + HeroLayout.expandedHeight(...)`.
  static double expandedHeight({
    required double titleHeight,
    required double amountMax,
  }) =>
      chromeTopInset +
      chromeRowHeight +
      aboveTitle +
      titleHeight +
      titleAmountGap +
      amountMax +
      belowAmount;

  /// Posición Y del amount cuando el hero está expandido, relativa a
  /// `topPadding`. Complementaria de `expandedHeight`.
  static double expandedAmountY({
    required double titleHeight,
    required double amountMax,
  }) =>
      expandedHeight(titleHeight: titleHeight, amountMax: amountMax) -
      belowAmount -
      amountMax;
}
