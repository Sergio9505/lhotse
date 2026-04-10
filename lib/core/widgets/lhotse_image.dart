import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Smart image widget: uses Image.asset for paths starting with 'assets/',
/// Image.network for URLs. Shared error builder.
class LhotseImage extends StatelessWidget {
  const LhotseImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
  });

  final String source;
  final BoxFit fit;

  bool get _isAsset => source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (_isAsset) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (_, _, _) => Container(color: AppColors.surface),
      );
    }
    return Image.network(
      source,
      fit: fit,
      errorBuilder: (_, _, _) => Container(color: AppColors.surface),
    );
  }
}
