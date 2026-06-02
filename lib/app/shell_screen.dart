import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/auth/biometric_lock_controller.dart';
import '../core/notifications/onesignal_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/biometric_soft_ask_sheet.dart';
import '../features/home/presentation/welcome_video_screen.dart';
import '../features/notifications/data/notifications_provider.dart';
import '../features/notifications/presentation/push_soft_ask_sheet.dart';
import '../features/onboarding/data/onboarding_repository.dart';

// Navbar labels — uppercase, consistent with app typography
const _kLabelInicio = 'INICIO';
const _kLabelFirmas = 'FIRMAS';
const _kLabelBuscar = 'BUSCAR';
const _kLabelEstrategia = 'ESTRATEGIA';
const _kLabelPerfil = 'PERFIL';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  /// Lives at process scope. Cold-start = new attempt; rebuild caused by
  /// hot-reload or tab change won't re-trigger (the shell itself isn't
  /// disposed in IndexedStack).
  static bool _coldStartSoftAskAttempted = false;

  @override
  void initState() {
    super.initState();
    if (_coldStartSoftAskAttempted) return;
    _coldStartSoftAskAttempted = true;
    // First-run interstitials, in a single deterministic order so they never
    // stack: (1) push permission → (2) Face ID opt-in → (3) CEO welcome video.
    // The welcome video must come AFTER the permission sheets (it blocks the
    // app), so it lives at the tail of this awaited chain.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Short delay so the user sees Inicio before the first sheet appears.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // (1) Push (communication) permission soft-ask.
      if (await OneSignalService.canShowSoftAsk()) {
        if (!mounted) return;
        await showPushSoftAsk(context);
      }

      // (2) Face ID / biometric opt-in (moved here from HomeScreen so the
      // ordering vs the welcome video is deterministic).
      if (!mounted) return;
      await _maybeAskForBiometric();

      // (3) One-time CEO welcome video — blocking, after the permission flow.
      if (!mounted) return;
      await _maybeShowWelcomeVideo();
    });
  }

  Future<void> _maybeAskForBiometric() async {
    try {
      await ref.read(biometricLockControllerProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final lock = ref.read(biometricLockControllerProvider.notifier);
    if (!await lock.shouldShowSoftAsk()) return;
    if (!mounted) return;
    final activated = await showBiometricSoftAsk(context, ref);
    if (!mounted || !activated) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Face ID activado.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _maybeShowWelcomeVideo() async {
    // Only on the Inicio tab — the welcome lives on Home (a brand-new user
    // lands there). If somehow on another tab, defer to a future session.
    if (widget.navigationShell.currentIndex != 0) return;
    bool seen;
    try {
      seen = await ref.read(onboardingRepositoryProvider).hasSeenWelcome();
    } catch (_) {
      // Fail open: a read error must never block the user behind the video.
      return;
    }
    if (seen || !mounted) return;
    await showWelcomeVideo(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: _LhotseNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        unreadCount: ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0,
        onTap: (i) => widget.navigationShell.goBranch(
          i,
          initialLocation: i == widget.navigationShell.currentIndex,
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
