import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../../../core/widgets/lhotse_section_label.dart';
import 'fullscreen_virtual_tour.dart';

class VirtualTourSection extends StatelessWidget {
  const VirtualTourSection({
    super.key,
    required this.imageUrl,
    required this.tourUrl,
    this.label = 'TOUR VIRTUAL',
  });

  final String imageUrl;
  final String tourUrl;
  final String label;

  void _open(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenVirtualTour(tourUrl: tourUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LhotseSectionLabel(label: label),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GestureDetector(
            onTap: () => _open(context),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LhotseImage(imageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x66000000)),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsThin.arrowsOutSimple,
                          size: 32,
                          color: AppColors.textOnDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'INICIAR TOUR',
                          style: AppTypography.labelUppercaseMd.copyWith(
                            color: AppColors.textOnDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
