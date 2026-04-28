import 'package:flutter/material.dart';

/// Centered frosted-glass play button overlay for video poster thumbnails.
/// Used on news cards (catalog, detail hero, feed) where the video is
/// "content to listen to" — not ambient — so autoplay-muted is inappropriate.
class LhotsePlayButton extends StatelessWidget {
  const LhotsePlayButton({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 25),
          ],
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
