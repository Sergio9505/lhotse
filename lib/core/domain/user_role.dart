import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../theme/app_colors.dart';

enum UserRole {
  @JsonValue('viewer')
  viewer,
  @JsonValue('investor')
  investor,
  @JsonValue('investor_vip')
  investorVip;

  String get label => switch (this) {
        UserRole.viewer => 'VISITANTE',
        UserRole.investor => 'INVERSOR',
        UserRole.investorVip => 'VIP',
      };

  Color get badgeColor => switch (this) {
        UserRole.viewer => AppColors.accentMuted,
        UserRole.investor => AppColors.primary,
        UserRole.investorVip => AppColors.gold,
      };
}
