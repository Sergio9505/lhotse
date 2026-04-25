import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      _emailController.text = profile?.email ?? '';
      _phoneController.text = profile?.phone ?? '';
      _cityController.text = profile?.city ?? '';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserIdProvider).valueOrNull;
      if (userId == null) return;
      await ref.read(supabaseClientProvider).from('user_profiles').update({
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
      }).eq('id', userId);
      ref.invalidate(currentUserProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(topPadding: topPadding),

            const SizedBox(height: AppSpacing.xl),

            // Nombre/apellidos — read-only (bloqueados por KYC)
            _ReadOnlyField(
              label: 'NOMBRE',
              value: ref.watch(currentUserProfileProvider).valueOrNull?.fullName
                  ?? '—',
            ),

            const SizedBox(height: AppSpacing.md),

            // Editable fields
            _EditableField(
              label: 'EMAIL',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            _EditableField(
              label: 'TELÉFONO',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            _EditableField(
              label: 'CIUDAD',
              controller: _cityController,
              isLast: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: _SaveButton(
                  onTap: _save,
                  isLoading: _saving,
                ),
              ),
            ),

            SizedBox(height: bottomPadding + AppSpacing.xl),
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
      padding: EdgeInsets.fromLTRB(AppSpacing.sm, topPadding + 16, AppSpacing.lg, 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const LhotseBackButton.onSurface(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'DATOS PERSONALES',
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

// ── Read-only row (name, locked by KYC) ──────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.labelUppercaseSm.copyWith(
                color: AppColors.accentMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyReading.copyWith(
                color: AppColors.accentMuted,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          const PhosphorIconWidget(size: 14, color: AppColors.accentMuted),
        ],
      ),
    );
  }
}

// Minimal lock icon placeholder (avoids importing phosphor just for this)
class PhosphorIconWidget extends StatelessWidget {
  const PhosphorIconWidget({super.key, this.size = 16, this.color = AppColors.accentMuted});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Icon(Icons.lock_outline, size: size, color: color);
}

// ── Editable field ────────────────────────────────────────────────────────────

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.isLast = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: isLast
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
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.labelUppercaseSm.copyWith(
                color: AppColors.accentMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              style: AppTypography.bodyReading.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.primary,
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'GUARDAR',
                    style: AppTypography.labelUppercaseMd.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
