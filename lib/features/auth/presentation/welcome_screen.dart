import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/lhotse_image.dart';
import '../../../app/router.dart';

// Drone shot of a luxury villa with pool — free commercial use (Coverr)
// Replace with branded content before production.
const _kVideoUrl =
    'https://cdn.coverr.co/videos/coverr-villa-with-a-swimming-pool-6618/720p.mp4';

// Ken Burns fallback — shown immediately while video loads (or if it fails)
const _kImages = [
  'assets/images/salon_dark.webp', // local — always available
  'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=1200&q=85',
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=85',
];

// Ken Burns zoom direction varies per image for visual variety
const _kAlignments = [
  Alignment.center,
  Alignment.centerLeft,
  Alignment.topRight,
];

const _kSlideDuration = Duration(seconds: 7);
const _kCrossfadeDuration = Duration(milliseconds: 1500);
const _kVideoFadeIn = Duration(milliseconds: 800);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Ken Burns ──────────────────────────────────────────────────────────────
  late final AnimationController _kenBurns;
  late final Animation<double> _kenBurnsAnim;
  late final Timer _slideTimer;
  int _imageIndex = 0;

  // ── Video ──────────────────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    // Ken Burns starts immediately — 1.0 → 1.08 slow zoom per image
    _kenBurns = AnimationController(
      vsync: this,
      duration: _kSlideDuration,
    )..forward();

    _kenBurnsAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _kenBurns, curve: Curves.easeInOut),
    );

    _slideTimer = Timer.periodic(_kSlideDuration, (_) {
      if (!mounted || _videoReady) return; // stop cycling once video is up
      setState(() => _imageIndex = (_imageIndex + 1) % _kImages.length);
      _kenBurns
        ..reset()
        ..forward();
    });

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_kVideoUrl),
      );
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoReady = true;
        });
      } else {
        controller.dispose();
      }
    } catch (_) {
      // Video failed — Ken Burns fallback stays active, no error shown
    }
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    _slideTimer.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Ken Burns slideshow — always under, visible while video loads ─
            AnimatedSwitcher(
              duration: _kCrossfadeDuration,
              child: _KenBurnsBackground(
                key: ValueKey(_imageIndex),
                imageUrl: _kImages[_imageIndex],
                alignment: _kAlignments[_imageIndex],
                animation: _kenBurnsAnim,
              ),
            ),

            // ── Video — fades in over Ken Burns once initialized ────────────
            if (_videoController != null)
              AnimatedOpacity(
                duration: _kVideoFadeIn,
                opacity: _videoReady ? 1.0 : 0.0,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              ),

            // ── Velvet gradient overlay ─────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.65,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.25, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // ── Branding + CTA ──────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  bottomPadding > 0 ? bottomPadding + 24 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo — hero visual
                    SvgPicture.asset(
                      'assets/images/lhotse_logo.svg',
                      height: 44,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tagline — engraved whisper
                    Text(
                      'Inversión inmobiliaria estratégica',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Campton',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 56),

                    // CTA — outline invitation
                    _AuthButton(
                      label: 'INICIAR SESIÓN',
                      onTap: () => context.push(AppRoutes.login),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ken Burns background ─────────────────────────────────────────────────────

class _KenBurnsBackground extends StatelessWidget {
  const _KenBurnsBackground({
    super.key,
    required this.imageUrl,
    required this.alignment,
    required this.animation,
  });

  final String imageUrl;
  final Alignment alignment;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.scale(
        scale: animation.value,
        alignment: alignment,
        child: child,
      ),
      child: LhotseImage(imageUrl, fit: BoxFit.cover),
    );
  }
}

// ── Auth button (pure outline) ────────────────────────────────────────────────

class _AuthButton extends StatefulWidget {
  const _AuthButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Campton',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
