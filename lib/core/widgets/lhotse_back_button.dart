import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Back button with two variants:
/// - [LhotseBackButton.onImage] — frosted glass circle for use over photos
/// - [LhotseBackButton.onSurface] — minimal arrow for beige/solid backgrounds
class LhotseBackButton extends StatefulWidget {
  const LhotseBackButton.onImage({
    super.key,
    this.onTap,
  }) : _variant = _Variant.onImage;

  const LhotseBackButton.onSurface({
    super.key,
    this.onTap,
  }) : _variant = _Variant.onSurface;

  /// Custom tap handler. Defaults to `context.pop()`.
  final VoidCallback? onTap;

  final _Variant _variant;

  /// Icon size used across both variants.
  static const double _iconSize = 20;

  /// Minimum touch target (Apple HIG: 44px).
  static const double _hitSize = 44;

  @override
  State<LhotseBackButton> createState() => _LhotseBackButtonState();
}

enum _Variant { onImage, onSurface }

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
          child: widget._variant == _Variant.onImage
              ? _buildFrosted()
              : _buildSurface(),
        ),
      ),
    );
  }

  Widget _buildFrosted() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _pressed ? 0.7 : 1.0,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.arrowLeft,
                size: LhotseBackButton._iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurface() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _pressed ? 0.4 : 1.0,
      child: const Icon(
        LucideIcons.arrowLeft,
        size: LhotseBackButton._iconSize,
        color: AppColors.textPrimary,
      ),
    );
  }
}
