import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lhotse wordmark / icon. Renders the brand SVG tinted with [color] so the
/// same mark can live on beige headers (black) and dark heroes / media
/// (white) without shipping two assets.
class LhotseMark extends StatelessWidget {
  const LhotseMark({
    super.key,
    required this.color,
    this.height = 20,
  });

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SvgPicture.asset(
        'assets/images/lhotse_logo.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
