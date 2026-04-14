// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  fullName: json['full_name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.viewer,
  memberSince: json['member_since'] == null
      ? null
      : DateTime.parse(json['member_since'] as String),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'avatar_url': instance.avatarUrl,
      'city': instance.city,
      'country': instance.country,
      'role': _$UserRoleEnumMap[instance.role]!,
      'member_since': instance.memberSince?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.viewer: 'viewer',
  UserRole.investor: 'investor',
  UserRole.investorVip: 'investor_vip',
};
