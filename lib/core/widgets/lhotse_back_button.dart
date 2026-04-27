import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';

/// Back button with two variants:
/// - [LhotseBackButton.overImage] — bare arrow over a hero, colour driven by
///   `useLightOverlay` (same flag as the Lhotse wordmark on Home). No frosted
///   container — the editorial chrome stays minimal.
/// - [LhotseBackButton.onSurface] — minimal arrow for beige/solid backgrounds.
class LhotseBackButton extends StatefulWidget {
  const LhotseBackButton.overImage({
    super.key,
    required this.useLightOverlay,
    this.onTap,
  }) : _variant = _Variant.overImage;

  const LhotseBackButton.onSurface({
    super.key,
    this.onTap,
  })  : _variant = _Variant.onSurface,
        useLightOverlay = true;

  /// Custom tap handler. Defaults to `context.pop()`.
  final VoidCallback? onTap;

  final _Variant _variant;

  /// Governs arrow colour on the `overImage` variant.
  /// `true` → white (hero is dark); `false` → black (hero is light).
  final bool useLightOverlay;

  static const double _iconSize = 24;
  static const double _hitSize = 44;

  @override
  State<LhotseBackButton> createState() => _LhotseBackButtonState();
}

enum _Variant { overImage, onSurface }

class _LhotseBackButtonState extends State<LhotseBackButton> {
  bool _pressed = false;

  void _handleTap() {
    (widget.onTap ?? () => context.pop())();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: LhotseBackButton._hitSize,
        height: LhotseBackButton._hitSize,
        child: Center(
          child: widget._variant == _Variant.overImage
              ? _buildOverImage()
              : _buildSurface(),
        ),
      ),
    );
  }

  Widget _buildOverImage() {
    final targetColor = widget.useLightOverlay
        ? AppColors.textOnDark
        : AppColors.primary;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _pressed ? 0.7 : 1.0,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: targetColor),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, color, _) => PhosphorIcon(
          PhosphorIconsThin.arrowLeft,
          size: LhotseBackButton._iconSize,
          color: color ?? targetColor,
        ),
      ),
    );
  }

  Widget _buildSurface() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _pressed ? 0.4 : 1.0,
      child: const PhosphorIcon(
        PhosphorIconsThin.arrowLeft,
        size: LhotseBackButton._iconSize,
        color: AppColors.textPrimary,
      ),
    );
  }
}
