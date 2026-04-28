import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';

/// Editorial underline text field used in auth screens.
///
/// - Label: caption uppercase, accentMuted, letterSpacing 1.8
/// - Field: underline-only border, Campton 18px w400, no background
/// - Error: caption below, danger color
/// - Password: eye/eyeSlash toggle suffix icon
class LhotseAuthField extends StatefulWidget {
  const LhotseAuthField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.errorText,
    this.autofocus = false,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LhotseAuthField> createState() => _LhotseAuthFieldState();
}

class _LhotseAuthFieldState extends State<LhotseAuthField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label.toUpperCase(),
          // EXCEPTION: w400 — input label is subdued caption, not an active control
          style: AppTypography.labelUppercaseSm.copyWith(
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),

        // Input
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          onSubmitted: widget.onSubmitted,
          style: AppTypography.bodyInput.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textPrimary, width: 0.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.textPrimary, width: 1),
            ),
            filled: false,
            errorText: null,
            suffixIcon: widget.obscureText
                ? GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: PhosphorIcon(
                        _obscured
                            ? PhosphorIconsThin.eye
                            : PhosphorIconsThin.eyeSlash,
                        size: 20,
                        color: AppColors.accentMuted,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ),

        // Error
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: AppTypography.annotation.copyWith(
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
