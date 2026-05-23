import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../../profile/data/user_requests_provider.dart';

/// Shows the "Solicitar información" bottom sheet for a project currently
/// in fundraising (`is_fundraising_open = true`). The CTA submits a
/// `user_requests` row with `type = 'project_info'` + `project_id` on first
/// tap and reflects "SOLICITUD EN ESTUDIO" on subsequent opens while a
/// non-declined request exists for this (user, project) pair. Mirrors the
/// state-aware shape of `vip_lock_sheet.dart`.
void showRequestInfoSheet(BuildContext context, ProjectData project) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => LhotseBottomSheetBody(
      title: project.name,
      titleStyle: AppTypography.editorialTitle.copyWith(
        color: AppColors.textPrimary,
      ),
      bodyBuilder: (bottomPadding) => _RequestInfoSheetBody(
        project: project,
        bottomPadding: bottomPadding,
      ),
    ),
  );
}

class _RequestInfoSheetBody extends ConsumerWidget {
  const _RequestInfoSheetBody({
    required this.project,
    required this.bottomPadding,
  });

  final ProjectData project;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exists = ref
            .watch(userProjectRequestExistsProvider(project.id))
            .valueOrNull ??
        false;

    final label = exists ? 'SOLICITUD EN ESTUDIO' : 'SOLICITAR INFORMACIÓN';

    Future<void> onTap() async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        await submitUserRequest(
          ref,
          UserRequestType.projectInfo,
          projectId: project.id,
        );
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Solicitud recibida. Te contactaremos pronto.'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar la solicitud. Inténtalo de nuevo.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: LhotseImage.poster(
              videoUrl: project.videoUrl,
              imageUrl: project.imageUrl,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            project.brand.toUpperCase(),
            style: AppTypography.labelUppercaseSm.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          if (project.tagline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              project.tagline,
              style: AppTypography.annotationParagraph.copyWith(
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: exists ? null : onTap,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: exists ? 0.6 : 1.0,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                color: AppColors.primary,
                child: Text(
                  label,
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
