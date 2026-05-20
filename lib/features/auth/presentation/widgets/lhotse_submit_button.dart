import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Editorial submit button used across auth screens.
class LhotseSubmitButton extends StatefulWidget {
  const LhotseSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  /// When false, the button is rendered at 40% opacity and the tap is
  /// swallowed. Used by signup to gate submit until the legal checkbox
  /// has been ticked.
  final bool enabled;

  @override
  State<LhotseSubmitButton> createState() => _LhotseSubmitButtonState();
}

class _LhotseSubmitButtonState extends State<LhotseSubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final blocked = widget.isLoading || !widget.enabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: blocked ? null : (_) => setState(() => _pressed = true),
      onTapUp: blocked
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: !widget.enabled ? 0.4 : (_pressed ? 0.6 : 1.0),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          color: AppColors.primary,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
