import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// 6-digit OTP input rendered as a single editorial underline field with
/// generous letter-spacing — coherent with [LhotseAuthField], avoiding the
/// "corporate boxed PIN" pattern.
class LhotseOtpField extends StatelessWidget {
  const LhotseOtpField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.autofocus = true,
    this.length = 6,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final int length;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      maxLength: length,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ],
      style: AppTypography.bodyInput.copyWith(
        color: AppColors.textPrimary,
        fontSize: 28,
        letterSpacing: 12,
      ),
      onChanged: (value) {
        if (value.length == length) onCompleted?.call(value);
      },
      decoration: const InputDecoration(
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimary, width: 0.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimary, width: 1),
        ),
        filled: false,
      ),
    );
  }
}
