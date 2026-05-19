import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/user_role.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    @JsonKey(name: 'full_name') String? fullName,
    String? email,
    String? phone,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? city,
    String? country,
    @Default(UserRole.viewer) UserRole role,
    @JsonKey(name: 'member_since') DateTime? memberSince,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // `admin` is operational metadata in the DB (used by RLS policies via
    // `is_admin()` for storage, user_requests, user_onboarding). On the
    // client we treat admins as VIP investors: same Strategy access, gold
    // badge, all VIP-gated features. Normalised here, at the boundary, so
    // `UserRole` never sees a value that shouldn't gate UI.
    final normalised = json['role'] == 'admin'
        ? {...json, 'role': 'investor_vip'}
        : json;
    return _$UserProfileFromJson(normalised);
  }
}
