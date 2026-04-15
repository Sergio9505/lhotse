import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../auth/presentation/widgets/lhotse_auth_field.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _biometric = true;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(topPadding: topPadding),

          const SizedBox(height: AppSpacing.xl),

          // Menu items
          _ActionRow(
            icon: PhosphorIconsThin.key,
            label: 'Cambiar contraseña',
            onTap: () => _showChangePasswordSheet(context),
          ),
          _ToggleRow(
            icon: PhosphorIconsThin.fingerprint,
            label: 'Autenticación biométrica',
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          _ActionRow(
            icon: PhosphorIconsThin.shieldCheck,
            label: 'Verificación en dos pasos',
            trailing: Text(
              'ACTIVADA',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF2D6A4F),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
            ),
            onTap: () {},
          ),
          _ActionRow(
            icon: PhosphorIconsThin.devices,
            label: 'Cerrar todas las sesiones',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final newPassController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Text(
                    'CAMBIAR CONTRASEÑA',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: LhotseAuthField(
                    controller: newPassController,
                    label: 'Nueva contraseña',
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: LhotseAuthField(
                    controller: confirmController,
                    label: 'Confirmar contraseña',
                    obscureText: true,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                    child: Text(
                      error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: GestureDetector(
                    onTap: saving
                        ? null
                        : () async {
                            final newPass = newPassController.text.trim();
                            final confirm = confirmController.text.trim();
                            if (newPass.length < 8) {
                              setSheet(() => error =
                                  'La contraseña debe tener al menos 8 caracteres');
                              return;
                            }
                            if (newPass != confirm) {
                              setSheet(
                                  () => error = 'Las contraseñas no coinciden');
                              return;
                            }
                            setSheet(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              await ref
                                  .read(supabaseClientProvider)
                                  .auth
                                  .updateUser(UserAttributes(password: newPass));
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            } catch (e) {
                              setSheet(() {
                                saving = false;
                                error = 'Error: ${e.toString()}';
                              });
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: AppColors.primary,
                      child: Center(
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white),
                              )
                            : Text(
                                'GUARDAR',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textOnDark,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
              'SEGURIDAD',
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
// Action row — tappable menu item
// ---------------------------------------------------------------------------

class _ActionRow extends StatefulWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
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
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              PhosphorIcon(
                widget.icon,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label.toUpperCase(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.trailing == null)
                const PhosphorIcon(
                  PhosphorIconsThin.caretRight,
                  size: 14,
                  color: AppColors.accentMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle row
// ---------------------------------------------------------------------------

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 12,
      ),
      child: Row(
        children: [
          PhosphorIcon(
            icon,
            size: 16,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: value
                      ? AppColors.primary
                      : AppColors.textPrimary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: value
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 13,
                        color: AppColors.textOnDark,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
