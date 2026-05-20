import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';

/// Editorial checkbox row used in signup + onboarding consent step. 18×18
/// caja, tick `PhosphorIconsThin.check` when on, whole row tappable. No
/// Material `Checkbox` (the ripple breaks the Hermès/Sotheby's voice).
class ConsentCheckboxRow extends StatelessWidget {
  const ConsentCheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: value
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.4),
                width: value ? 1.0 : 0.5,
              ),
              color: value ? AppColors.textPrimary : Colors.transparent,
            ),
            child: value
                ? const PhosphorIcon(
                    PhosphorIconsThin.check,
                    size: 14,
                    color: AppColors.textOnDark,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Legal consent — required. Links open the embedded WebView for the
/// terms + privacy pages (lhotsegroup.com).
class LegalConsentCheckbox extends StatelessWidget {
  const LegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final body = AppTypography.annotationParagraph.copyWith(
      color: value ? AppColors.textPrimary : AppColors.accentMuted,
    );
    final link = body.copyWith(
      color: AppColors.textPrimary,
      decoration: TextDecoration.underline,
      decorationThickness: 0.5,
    );

    return ConsentCheckboxRow(
      value: value,
      onChanged: onChanged,
      child: RichText(
        text: TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'He leído y acepto los '),
            TextSpan(
              text: 'Términos',
              style: link,
              recognizer: _Tap(onTermsTap),
            ),
            const TextSpan(text: ' y la '),
            TextSpan(
              text: 'Política de Privacidad',
              style: link,
              recognizer: _Tap(onPrivacyTap),
            ),
            const TextSpan(text: ' de Lhotse Group.'),
          ],
        ),
      ),
    );
  }
}

/// Marketing consent — optional (RGPD Considerando 32). Default off.
class MarketingConsentCheckbox extends StatelessWidget {
  const MarketingConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConsentCheckboxRow(
      value: value,
      onChanged: onChanged,
      child: Text(
        'Quiero recibir comunicaciones sobre nuevos proyectos e '
        'invitaciones VIP.',
        style: AppTypography.annotationParagraph.copyWith(
          color: value ? AppColors.textPrimary : AppColors.accentMuted,
        ),
      ),
    );
  }
}

/// Lightweight TapGestureRecognizer wrapper for the inline TextSpan links.
class _Tap extends TapGestureRecognizer {
  _Tap(VoidCallback onTap) {
    this.onTap = onTap;
  }
}
