import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(topPadding: topPadding),

            const SizedBox(height: AppSpacing.xl),

            // Form fields — nombre/apellidos no son editables (bloqueados por KYC)
            const _TextField(label: 'EMAIL', value: 'a.garcia@email.com'),
            const _TextField(label: 'TELÉFONO', value: '+34 612 345 678'),
            const _TextField(
              label: 'DIRECCIÓN',
              value: 'Calle Gran Vía 42, Madrid',
              isLast: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: _SaveButton(onTap: () {}),
              ),
            ),

            SizedBox(height: bottomPadding + AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        topPadding + 16,
        AppSpacing.lg,
        16,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const LhotseBackButton.onSurface(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'DATOS PERSONALES',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text field row
// ---------------------------------------------------------------------------

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
            ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.accentMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.primary,
          child: Center(
            child: Text(
              'GUARDAR',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textOnDark,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
