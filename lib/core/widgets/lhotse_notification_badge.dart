import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Red dot badge (6px) positioned top-right of its child.
/// Shows only when [show] is true.
class LhotseNotificationBadge extends StatelessWidget {
  const LhotseNotificationBadge({
    super.key,
    required this.child,
    this.show = true,
    this.count,
  });

  final Widget child;
  final bool show;
  final int? count;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -2,
          child: count != null && count! > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      count! > 99 ? '99+' : '$count',
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        height: 1.2,
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ],
    );
  }
}
