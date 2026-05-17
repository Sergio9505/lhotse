import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';

/// Modal bottom sheet that confirms permanent account deletion. Calls
/// `delete_my_account` RPC (SECURITY DEFINER) which wipes auth.users for
/// the caller; downstream FKs cascade user-side data and SET NULL the
/// contract rows so the asset history stays anonymised. After success the
/// router redirects to /welcome via the auth listener — we just pop.
Future<void> showDeleteAccountSheet(
    BuildContext context, WidgetRef ref) async {
  bool acknowledged = false;
  String? error;
  bool saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    isDismissible: false,
    enableDrag: false,
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
                  'ELIMINAR CUENTA',
                  style: AppTypography.titleUppercase.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Esta acción es permanente. Se eliminarán sus datos '
                  'personales, notificaciones y preferencias. Sus '
                  'inversiones se conservarán anonimizadas en nuestros '
                  'registros por motivos legales y contables.',
                  style: AppTypography.annotationParagraph.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: saving
                      ? null
                      : () => setSheet(() => acknowledged = !acknowledged),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Checkbox(checked: acknowledged),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Entiendo que esta acción es irreversible.',
                          style: AppTypography.annotationParagraph.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: GestureDetector(
                  onTap: (!acknowledged || saving)
                      ? null
                      : () async {
                          setSheet(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .deleteMyAccount();
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } catch (e) {
                            setSheet(() {
                              saving = false;
                              error =
                                  'No se pudo eliminar la cuenta. Inténtelo de nuevo.';
                            });
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: acknowledged
                        ? AppColors.danger
                        : AppColors.danger.withValues(alpha: 0.4),
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
                              'ELIMINAR MI CUENTA',
                              style: AppTypography.labelUppercaseMd
                                  .copyWith(
                                color: AppColors.textOnDark,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: GestureDetector(
                  onTap: saving ? null : () => Navigator.of(ctx).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'CANCELAR',
                        style: AppTypography.labelUppercaseMd.copyWith(
                          color: AppColors.textPrimary,
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

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.textPrimary : Colors.transparent,
        border: Border.all(
          color: checked
              ? AppColors.textPrimary
              : AppColors.textPrimary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: checked
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}
