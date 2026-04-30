import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LhotseAsyncLoading extends StatelessWidget {
  const LhotseAsyncLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
    );
  }
}

class LhotseAsyncError extends StatelessWidget {
  const LhotseAsyncError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTypography.bodyReading
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Inténtalo de nuevo',
                style: AppTypography.bodyReading
                    .copyWith(color: AppColors.accentMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
