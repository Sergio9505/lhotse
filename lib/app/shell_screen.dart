import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/data/mock/mock_notifications.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/lhotse_notification_badge.dart';

// Navbar labels — uppercase, consistent with app typography
const _kLabelInicio = 'INICIO';
const _kLabelFirmas = 'FIRMAS';
const _kLabelBuscar = 'BUSCAR';
const _kLabelEstrategia = 'ESTRATEGIA';
const _kLabelPerfil = 'PERFIL';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _LhotseNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _LhotseNavBar extends StatelessWidget {
  const _LhotseNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(icon: LucideIcons.home, label: _kLabelInicio),
    _NavItemData(icon: LucideIcons.layers, label: _kLabelFirmas),
    _NavItemData(icon: LucideIcons.search, label: _kLabelBuscar),
    _NavItemData(icon: LucideIcons.compass, label: _kLabelEstrategia),
    _NavItemData(icon: LucideIcons.user, label: _kLabelPerfil),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.navBorderTop, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navShadow,
            blurRadius: 27,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LhotseNotificationBadge(
                      show: i == 3 && // ESTRATEGIA tab
                          mockNotifications.any((n) => !n.isRead),
                      child: Icon(
                        _items[i].icon,
                        size: 22,
                        color: selected
                            ? AppColors.textOnDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _items[i].label,
                      style: AppTypography.labelSmall.copyWith(
                        color: selected
                            ? AppColors.textOnDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
