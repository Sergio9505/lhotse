import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/user_role.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  /// `fullName` is read from a DB GENERATED column (concat of first_name +
  /// last_name). Display-only on the client — writers must set firstName /
  /// lastName instead; PostgREST rejects direct writes to `full_name`.
  const factory UserProfile({
    required String id,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? city,
    String? country,
    @Default(UserRole.viewer) UserRole role,
    DateTime? memberSince,
  }) = _UserProfile;

  /// Maps a Supabase `user_profiles` row to the domain model. Mapping is
  /// written by hand (no json_serializable) because the Freezed 3.x
  /// build_runner pipeline in this repo refuses to regenerate the .g.dart
  /// reliably; the model is small enough that the manual cost is trivial.
  ///
  /// `admin` is operational DB metadata (used by RLS policies via
  /// `is_admin()` for storage, user_requests, user_onboarding). On the
  /// client we treat admins as VIP investors: same Strategy access, gold
  /// badge, all VIP-gated features. Normalised here at the boundary so
  /// `UserRole` never sees a value that shouldn't gate UI.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      role: _parseRole(json['role'] as String?),
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : null,
    );
  }
}

UserRole _parseRole(String? value) {
  // Admins are treated as VIP investors client-side (see fromJson docstring).
  if (value == null || value == 'admin' || value == 'investor_vip') {
    return value == 'admin' || value == 'investor_vip'
        ? UserRole.investorVip
        : UserRole.viewer;
  }
  return switch (value) {
    'investor' => UserRole.investor,
    'viewer' => UserRole.viewer,
    _ => UserRole.viewer,
  };
}
