import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/auth/biometric_lock_controller.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  List<BiometricType>? _types;
  bool? _available;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resolveBiometricCapability();
  }

  Future<void> _resolveBiometricCapability() async {
    final service = ref.read(biometricServiceProvider);
    final available = await service.isAvailable();
    final types = await service.availableTypes();
    if (!mounted) return;
    setState(() {
      _available = available;
      _types = types;
    });
  }

  /// "Face ID" on iOS faces, "Touch ID" on iOS fingerprints, "huella" on
  /// Android. Falls back to a neutral term if the OS hasn't reported types
  /// yet — only briefly visible during the async resolve.
  String get _biometricLabel {
    final t = _types;
    if (t == null) return 'biometría';
    if (t.contains(BiometricType.face)) return 'Face ID';
    if (t.contains(BiometricType.fingerprint)) {
      return Platform.isIOS ? 'Touch ID' : 'huella';
    }
    return 'biometría';
  }

  Future<void> _toggle(bool currentlyOn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final lock = ref.read(biometricLockControllerProvider.notifier);
      if (currentlyOn) {
        await lock.disableExplicitly();
      } else {
        final ok = await lock.activate(reason: 'Verificar su identidad');
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se ha activado.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final lockState = ref.watch(biometricLockControllerProvider);
    final enabled = lockState.valueOrNull?.enabled == true;
    final available = _available ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(topPadding: topPadding),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel(title: 'DESBLOQUEO'),
            const SizedBox(height: AppSpacing.xs),
            _ToggleRow(
              label: 'Desbloquear con $_biometricLabel',
              value: enabled,
              enabled: available && !_busy,
              onChanged: (_) => _toggle(enabled),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                available
                    ? 'Le pediremos $_biometricLabel al abrir Lhotse y tras '
                        'unos minutos sin actividad.'
                    : 'Configure $_biometricLabel en los ajustes de su '
                        'dispositivo para activar esta protección.',
                style: AppTypography.annotationParagraph.copyWith(
                  color: AppColors.accentMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.topPadding});
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.sm, topPadding + 16, AppSpacing.lg, 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const LhotseBackButton.onSurface(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'SEGURIDAD',
              style: AppTypography.titleUppercase.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged(!value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyReading.copyWith(
                  color: AppColors.textPrimary
                      .withValues(alpha: enabled ? 1 : 0.4),
                ),
              ),
            ),
            _Checkbox(value: value, enabled: enabled),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.value, this.enabled = true});
  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
          ? Center(
              child: Icon(
                Icons.check,
                size: 13,
                color: AppColors.textOnDark
                    .withValues(alpha: enabled ? 1 : 0.4),
              ),
            )
          : null,
    );
  }
}
