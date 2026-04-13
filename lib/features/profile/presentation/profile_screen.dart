import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _avatarUrl =
      'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=240&q=80';

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _ProfileHeader(topPadding: topPadding),

            const SizedBox(height: AppSpacing.lg),

            // Avatar + identity
            const _IdentitySection(),

            const SizedBox(height: AppSpacing.xl),

            // Gestión de cuenta
            const _SectionLabel(title: 'GESTIÓN DE CUENTA'),
            const SizedBox(height: AppSpacing.xs),
            const _MenuItem(
              icon: PhosphorIconsThin.identificationCard,
              label: 'Documentación Legal (KYC)',
            ),
            const _MenuItem(
              icon: PhosphorIconsThin.bellRinging,
              label: 'Preferencias & Alertas',
            ),
            const _MenuItem(
              icon: PhosphorIconsThin.shieldCheck,
              label: 'Seguridad & Privacidad',
            ),
            const _MenuItem(
              icon: PhosphorIconsThin.chatCircle,
              label: 'Contacto y Soporte',
              isLast: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Legal
            const _SectionLabel(title: 'LEGAL'),
            const SizedBox(height: AppSpacing.xs),
            const _MenuItem(
              icon: PhosphorIconsThin.fileText,
              label: 'Términos y Condiciones',
            ),
            const _MenuItem(
              icon: PhosphorIconsThin.lockKey,
              label: 'Política de Privacidad',
              isLast: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Lhotse Private banner
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _PrivateBanner(),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Logout
            const _LogoutButton(),

            const SizedBox(height: AppSpacing.md),

            // Version
            Text(
              'v1.2.0 · Build 8821',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentMuted,
                fontSize: 9,
              ),
            ),

            SizedBox(height: bottomPadding + AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + 16,
        AppSpacing.md,
        16,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PERFIL',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsThin.pencilSimple,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Identity section — avatar + role badge + name + metadata
// ---------------------------------------------------------------------------

class _IdentitySection extends StatelessWidget {
  const _IdentitySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar + badge stacked
        SizedBox(
          width: 140,
          child: Column(
            children: [
              // Circular avatar with thin border
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    ProfileScreen._avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: PhosphorIcon(
                          PhosphorIconsThin.user,
                          size: 48,
                          color: AppColors.accentMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Role badge — overlaps bottom of avatar
              Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  color: AppColors.primary,
                  child: Text(
                    'VISITANTE',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Name
        const SizedBox(height: 4),
        Text(
          'Alejandro García',
          style: AppTypography.headingLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // Metadata
        Opacity(
          opacity: 0.6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MIEMBRO DESDE 2021',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Text(
                'MADRID, ES',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — "TÍTULO ──────"
// ---------------------------------------------------------------------------

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
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.accentMuted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
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

// ---------------------------------------------------------------------------
// Menu item
// ---------------------------------------------------------------------------

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final bool isLast;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: widget.isLast
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                ),
          child: Row(
            children: [
              PhosphorIcon(
                widget.icon,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const PhosphorIcon(
                PhosphorIconsThin.caretRight,
                size: 14,
                color: AppColors.accentMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lhotse Private banner
// ---------------------------------------------------------------------------

class _PrivateBanner extends StatelessWidget {
  const _PrivateBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crown + "INVITACIÓN" badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsThin.crown,
                      size: 20,
                      color: AppColors.textOnDark,
                    ),
                    const Spacer(),
                    // "INVITACIÓN" badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.textOnDark,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'INVITACIÓN',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Lhotse Private',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Acceso exclusivo a rondas Pre-Seed y eventos de networking de alto nivel.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: AppSpacing.md),

                // CTA
                Row(
                  children: [
                    Text(
                      'SOLICITAR ACCESO',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const PhosphorIcon(
                      PhosphorIconsThin.arrowRight,
                      size: 12,
                      color: AppColors.textOnDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout button
// ---------------------------------------------------------------------------

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PhosphorIcon(
              PhosphorIconsThin.signOut,
              size: 14,
              color: AppColors.accentMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'CERRAR SESIÓN',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.accentMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
