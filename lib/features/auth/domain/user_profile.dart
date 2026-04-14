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

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
