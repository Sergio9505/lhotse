import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Editorial submit button used across auth screens.
class LhotseSubmitButton extends StatefulWidget {
  const LhotseSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<LhotseSubmitButton> createState() => _LhotseSubmitButtonState();
}

class _LhotseSubmitButtonState extends State<LhotseSubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
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
