import 'package:flutter/widgets.dart';

/// Non-linear text scaler aligned with iOS Dynamic Type behaviour.
///
/// Larger fonts (editorial titles, hero amounts) scale less than smaller
/// fonts (body, meta), preserving editorial composition while still giving
/// body text real accessibility headroom.
///
/// Curve (max scale by fontSize):
/// - fontSize ≤ 14 → max 1.30 (body, meta, labels)
/// - fontSize ≥ 36 → max 1.15 (editorial titles, hero)
/// - between 14 and 36 → linear interpolation (continuous, no visual jumps
///   during animations that cross the range — e.g. the strategy hero's
///   `amountSize = 28 + 18 * expandRatio`).
///
/// Lower bound is fixed at 1.0 — "Smaller Text" (iOS) is not honoured
/// because editorial composition assumes 1.0 as floor.
class LhotseTextScaler extends TextScaler {
  const LhotseTextScaler.fromSystem(this.systemScale);

  final double systemScale;

  double _maxScaleFor(double fontSize) {
    final t = ((fontSize - 14) / (36 - 14)).clamp(0.0, 1.0);
    return 1.30 + (1.15 - 1.30) * t;
  }

  @override
  double scale(double fontSize) {
    final maxScale = _maxScaleFor(fontSize);
    return fontSize * systemScale.clamp(1.0, maxScale);
  }

  /// Deprecated by the framework but still abstract on [TextScaler]. We
  /// expose the body-text effective scale (max 1.30) — the closest analogue
  /// to a single scalar — for any caller that still reads it.
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => systemScale.clamp(1.0, 1.30);

  @override
  bool operator ==(Object other) =>
      other is LhotseTextScaler && other.systemScale == systemScale;

  @override
  int get hashCode => systemScale.hashCode;
}
