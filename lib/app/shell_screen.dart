import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/data/notifications_provider.dart';

// Navbar labels — uppercase, consistent with app typography
const _kLabelInicio = 'INICIO';
const _kLabelFirmas = 'FIRMAS';
const _kLabelBuscar = 'BUSCAR';
const _kLabelEstrategia = 'ESTRATEGIA';
const _kLabelPerfil = 'PERFIL';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _LhotseNavBar(
        currentIndex: navigationShell.currentIndex,
        unreadCount: ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0,
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
    required this.unreadCount,
    required this.onTap,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(label: _kLabelInicio, icon: PhosphorIconsThin.house),
    _NavItemData(label: _kLabelFirmas, icon: PhosphorIconsThin.stack),
    _NavItemData(label: _kLabelBuscar, icon: PhosphorIconsThin.magnifyingGlass),
    _NavItemData(label: _kLabelEstrategia, icon: PhosphorIconsThin.chartLineUp),
    _NavItemData(label: _kLabelPerfil, icon: PhosphorIconsThin.user),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    SizedBox(
                      height: 22,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: PhosphorIcon(
                          _items[i].icon!,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Dot: black = active, red = notifications, transparent = default
                    Builder(builder: (_) {
                      final hasNotifications = i == 3 && unreadCount > 0;
                      final Color dotColor;
                      if (selected) {
                        dotColor = AppColors.textPrimary;
                      } else if (hasNotifications) {
                        dotColor = AppColors.danger;
                      } else {
                        dotColor = Colors.transparent;
                      }
                      return Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
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
    required this.label,
    this.icon,
  });

  final String label;
  final PhosphorIconData? icon;
}
