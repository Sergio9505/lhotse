import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_shell_header.dart';
import '../../auth/data/auth_repository.dart';
import '../data/avatar_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  String get _versionLabel {
    final info = _packageInfo;
    if (info == null) return '';
    return 'v${info.version}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            const LhotseShellHeader(),

            const SizedBox(height: AppSpacing.lg),

            // Avatar (tap → image picker) + name/metadata (tap → edit contact data)
            const _IdentitySection(),

            const SizedBox(height: AppSpacing.xl),

            // Gestión de cuenta
            const _SectionLabel(title: 'GESTIÓN DE CUENTA'),
            const SizedBox(height: AppSpacing.md),
            _MenuItem(
              icon: PhosphorIconsThin.identificationCard,
              label: 'Documentación Legal (KYC)',
              onTap: () => context.push('/profile/kyc'),
            ),
            _MenuItem(
              icon: PhosphorIconsThin.bell,
              label: 'Notificaciones',
              onTap: () => context.push('/profile/notifications'),
            ),
            _MenuItem(
              icon: PhosphorIconsThin.shieldCheck,
              label: 'Seguridad',
              onTap: () => context.push('/profile/security'),
            ),
            _MenuItem(
              icon: PhosphorIconsThin.chatCircle,
              label: 'Contacto y Soporte',
              onTap: () => context.push('/profile/support'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Legal
            const _SectionLabel(title: 'LEGAL'),
            const SizedBox(height: AppSpacing.md),
            _MenuItem(
              icon: PhosphorIconsThin.fileText,
              label: 'Términos y Condiciones',
              onTap: () => context.push('/profile/terms'),
            ),
            _MenuItem(
              icon: PhosphorIconsThin.lockKey,
              label: 'Política de Privacidad',
              onTap: () => context.push('/profile/privacy'),
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
            if (_versionLabel.isNotEmpty)
              Text(
                _versionLabel,
                style: AppTypography.labelUppercaseSm.copyWith(
                  color: AppColors.accentMuted,
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
// Identity section — avatar + role badge + name + metadata
// ---------------------------------------------------------------------------

class _IdentitySection extends ConsumerStatefulWidget {
  const _IdentitySection();

  @override
  ConsumerState<_IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends ConsumerState<_IdentitySection> {
  final _picker = ImagePicker();
  bool _uploading = false;

  void _showImageSourceSheet() {
    if (_uploading) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Cámara'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Biblioteca de fotos'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Widget _buildNetworkOrInitials(String? avatarUrl, String displayName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            _buildInitials(displayName),
      );
    }
    return _buildInitials(displayName);
  }

  Widget _buildInitials(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(
          initials,
          style: AppTypography.editorialTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 720,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await uploadAvatar(ref, file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la imagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final role = ref.watch(currentUserRoleProvider);
    final rawName = profile?.fullName?.trim() ?? '';
    final displayName = rawName.isEmpty ? 'Inversor' : rawName;
    final memberSince = profile?.memberSince;
    final city = profile?.city;
    final country = profile?.country;

    return Column(
      children: [
        // Avatar + badge stacked
        SizedBox(
          width: 140,
          child: Column(
            children: [
              // Circular avatar — tappable for image picker
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildNetworkOrInitials(
                            profile?.avatarUrl, displayName),
                        if (_uploading)
                          Container(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                  color: role.badgeColor,
                  child: Text(
                    role.label,
                    style: AppTypography.badgePill.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Name + metadata — tappable for edit contact data
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/profile/edit'),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xs),
              Text(
                displayName,
                style: AppTypography.editorialTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (memberSince != null)
                    Text(
                      'MIEMBRO DESDE ${memberSince.year}',
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  if (memberSince != null &&
                      (city != null || country != null)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.accentMuted.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                  if (city != null || country != null)
                    Text(
                      [?city, ?country].join(', ').toUpperCase(),
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                ],
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
            style: AppTypography.labelUppercaseMd.copyWith(
              color: AppColors.accentMuted,
              fontWeight: FontWeight.w400,
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          child: Row(
            children: [
              PhosphorIcon(
                widget.icon,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label.toUpperCase(),
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: AppColors.textPrimary,
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(
          top: BorderSide(color: AppColors.gold, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lhotse Private',
            style: AppTypography.editorialSubtitle.copyWith(
              color: AppColors.textOnDark,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Acceso exclusivo a rondas Pre-Seed y eventos de networking de alto nivel.',
            style: AppTypography.annotation.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.75),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // CTA
          Row(
            children: [
              Text(
                'SOLICITAR INVITACIÓN',
                style: AppTypography.labelUppercaseMd.copyWith(
                  color: AppColors.textOnDark,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const PhosphorIcon(
                PhosphorIconsThin.arrowRight,
                size: 14,
                color: AppColors.textOnDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout button
// ---------------------------------------------------------------------------

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(authRepositoryProvider).signOut(),
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
              style: AppTypography.labelUppercaseMd.copyWith(
                color: AppColors.accentMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
