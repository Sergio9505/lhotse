import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

class LhotseSearchField extends StatelessWidget {
  const LhotseSearchField({
    super.key,
    required this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.onClose,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClose;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsThin.magnifyingGlass,
            size: 20,
            color: AppColors.accentMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'Campton',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Campton',
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary.withValues(alpha: 0.41),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: PhosphorIcon(
                  PhosphorIconsThin.x,
                  size: 18,
                  color: AppColors.accentMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
