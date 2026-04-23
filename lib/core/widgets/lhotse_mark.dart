import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lhotse wordmark / icon. Renders the brand SVG tinted with [color] so the
/// same mark can live on beige headers (black) and dark heroes / media
/// (white) without shipping two assets.
///
/// `hasShadow` applies a soft drop shadow — use it only when the mark sits
/// over variable imagery (Home feed, Strategy hero) where contrast with the
/// background can't be guaranteed. Default false keeps the crisp rendering on
/// beige shells where shadow would be noise.
class LhotseMark extends StatelessWidget {
  const LhotseMark({
    super.key,
    required this.color,
    this.height = 20,
    this.hasShadow = false,
  });

  final Color color;
  final double height;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      height: height,
      child: SvgPicture.asset(
        'assets/images/lhotse_logo.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
    if (!hasShadow) return mark;
    // Soft drop shadow guarantees legibility over photographs with bright
    // or low-contrast regions. Kept subtle so it disappears on dark zones
    // and only supports contrast when needed.
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: mark,
    );
  }
}
