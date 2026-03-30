import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PERFIL')),
      body: const Center(
        child: Text('Profile', style: AppTypography.headingMedium),
      ),
    );
  }
}
