import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/supabase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/lhotse_auth_field.dart';

/// Modal bottom sheet to change the user's password. Validates minimum
/// length (8) + match between new and confirmation, then calls
/// `auth.updateUser(password)`. Reused from anywhere that wants a
/// one-action "Change password" entry point — there is no longer a
/// dedicated SecurityScreen wrapping a single action.
Future<void> showChangePasswordSheet(
    BuildContext context, WidgetRef ref) async {
  final newPassController = TextEditingController();
  final confirmController = TextEditingController();
  String? error;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                  style: AppTypography.titleUppercase.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: LhotseAuthField(
                  controller: newPassController,
                  label: 'Nueva contraseña',
                  obscureText: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    style: AppTypography.annotation.copyWith(
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
                            setSheet(() =>
                                error = 'Las contraseñas no coinciden');
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
                                .updateUser(
                                    UserAttributes(password: newPass));
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
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'GUARDAR',
                              style: AppTypography.labelUppercaseMd
                                  .copyWith(
                                color: AppColors.textOnDark,
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
