import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum UserRole {
  viewer,
  investor,
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

// Temporary mock — replace with auth provider when Supabase is connected
const kMockCurrentRole = UserRole.investor;
