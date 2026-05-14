import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/data/countries.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/otp_verify_screen.dart';
import '../../auth/presentation/widgets/lhotse_auth_field.dart';
import '../../auth/presentation/widgets/lhotse_country_picker.dart';
import '../../auth/presentation/widgets/lhotse_phone_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = LhotsePhoneController();
  Country _country = kDefaultCountry;

  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    _nameController.text = profile?.fullName ?? '';
    _cityController.text = profile?.city ?? '';

    // Parse current auth.users.phone (E.164 without '+', e.g. '34680591450')
    // into Country + localNumber for the LhotsePhoneField.
    final rawPhone = Supabase.instance.client.auth.currentUser?.phone ?? '';
    final parsed = _parsePhone(rawPhone);
    _phoneController.setCountry(parsed.country);
    _phoneController.setLocalNumber(parsed.localNumber);

    // Residence country from user_profiles.country (ISO 2-letter code).
    final iso = profile?.country;
    if (iso != null && iso.isNotEmpty) {
      for (final c in kCountries) {
        if (c.code == iso) {
          _country = c;
          break;
        }
      }
    }
  }

  ({Country country, String localNumber}) _parsePhone(String raw) {
    if (raw.isEmpty) return (country: kDefaultCountry, localNumber: '');
    // Match the longest dialCode prefix.
    Country? match;
    var matchLen = 0;
    for (final c in kCountries) {
      final dial = c.dialCode.startsWith('+')
          ? c.dialCode.substring(1)
          : c.dialCode;
      if (raw.startsWith(dial) && dial.length > matchLen) {
        match = c;
        matchLen = dial.length;
      }
    }
    if (match == null) return (country: kDefaultCountry, localNumber: raw);
    return (country: match, localNumber: raw.substring(matchLen));
  }

  Future<void> _pickCountry() async {
    final picked =
        await showLhotseCountryPicker(context, selected: _country);
    if (picked != null && mounted) {
      setState(() => _country = picked);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = ref.read(currentUserIdProvider).valueOrNull;
      if (userId == null) return;

      // Validate phone if any digits were entered.
      final newPhone = _phoneController.e164;
      if (newPhone == null && _phoneController.localNumber.isNotEmpty) {
        setState(() {
          _saving = false;
          _error = 'Introduce un teléfono válido.';
        });
        return;
      }

      final currentPhone =
          Supabase.instance.client.auth.currentUser?.phone ?? '';
      final newPhoneNormalized = newPhone?.replaceFirst('+', '');
      final phoneChanged =
          newPhoneNormalized != null && newPhoneNormalized != currentPhone;

      // 1) Persist non-auth fields to user_profiles. Email and phone are
      //    NOT touched here — email is read-only (managed by support);
      //    phone is owned by auth.users (SoT, ADR-63) and synced to
      //    user_profiles via trg_handle_user_updated on OTP verification.
      await ref.read(supabaseClientProvider).from('user_profiles').update({
        'full_name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _country.code,
      }).eq('id', userId);
      ref.invalidate(currentUserProfileProvider);

      if (!mounted) return;

      // 2) Phone change → OTP flow. Supabase stages newPhone in
      //    auth.users.phone_change; the current auth.users.phone stays
      //    untouched until verifyPhoneChangeOtp succeeds. If the user
      //    aborts, the old phone is preserved everywhere.
      if (phoneChanged) {
        await ref.read(authRepositoryProvider).attachPhone(newPhone!);
        if (!mounted) return;
        context.push(
          AppRoutes.otpVerify,
          extra: OtpVerifyArgs(
            phone: newPhone,
            purpose: OtpPurpose.signupVerification,
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _mapPhoneError(e.message);
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'No se pudieron guardar los cambios. Inténtalo de nuevo.';
        });
      }
      return;
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  String _mapPhoneError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('phone') && msg.contains('invalid')) {
      return 'Introduce un teléfono válido.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    final phoneAlreadyTaken = msg.contains('already registered') ||
        (msg.contains('user') && msg.contains('already')) ||
        (msg.contains('phone') &&
            (msg.contains('exists') ||
                msg.contains('taken') ||
                msg.contains('in use') ||
                msg.contains('duplicate')));
    if (phoneAlreadyTaken) {
      return 'Ese teléfono ya está vinculado a otra cuenta.';
    }
    if (msg.contains('sms') &&
        (msg.contains('provider') || msg.contains('disabled'))) {
      return 'No se puede enviar el SMS. Inténtalo más tarde.';
    }
    return 'No se pudieron guardar los cambios. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final email = ref.watch(currentUserProfileProvider).valueOrNull?.email;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(topPadding: topPadding),

            const SizedBox(height: AppSpacing.xl),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EmailDisplay(email: email),

                  const SizedBox(height: AppSpacing.xl),

                  LhotseAuthField(
                    controller: _nameController,
                    label: 'Nombre',
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  LhotsePhoneField(
                    controller: _phoneController,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _CountryRow(
                    label: 'País de residencia',
                    country: _country,
                    onTap: _pickCountry,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  LhotseAuthField(
                    controller: _cityController,
                    label: 'Ciudad',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: AppTypography.annotation.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    child: _SaveButton(
                      onTap: _save,
                      isLoading: _saving,
                    ),
                  ),
                ],
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
      padding: EdgeInsets.fromLTRB(
          AppSpacing.sm, topPadding + 16, AppSpacing.lg, 16),
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
              // forceStrutHeight collapses the line box to fontSize exact
              // (18pt instead of 21.6pt from height:1.2), eliminating the
              // asymmetric leading that pushes caps toward the top of the
              // box and visually misaligns them with the back arrow.
              strutStyle: const StrutStyle(
                fontSize: 18,
                height: 1.0,
                forceStrutHeight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Email display (read-only) ────────────────────────────────────────────────

class _EmailDisplay extends StatelessWidget {
  const _EmailDisplay({required this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMAIL',
          style: AppTypography.labelUppercaseSm.copyWith(
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email != null && email!.isNotEmpty ? email! : '—',
          style: AppTypography.bodyInput.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Country row (tappable selector) ──────────────────────────────────────────

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.label,
    required this.country,
    required this.onTap,
  });

  final String label;
  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelUppercaseSm.copyWith(
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    country.name,
                    style: AppTypography.bodyInput.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const PhosphorIcon(
                  PhosphorIconsThin.caretDown,
                  size: 14,
                  color: AppColors.accentMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Save button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap, required this.isLoading});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.primary,
        child: Center(
          child: isLoading
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
    );
  }
}
