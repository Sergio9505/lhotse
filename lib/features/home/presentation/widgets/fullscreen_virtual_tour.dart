import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';

/// Fullscreen WebView for interactive virtual tours (Matterport, Panoee,
/// Kuula, etc.). Provider-agnostic: loads any URL the project exposes.
///
/// Uses `flutter_inappwebview` over `webview_flutter` for native Fullscreen
/// API support, inline 360° autoplay on iOS, and finer WebGL control —
/// critical for 3D viewers.
class FullscreenVirtualTour extends StatefulWidget {
  const FullscreenVirtualTour({super.key, required this.tourUrl});

  final String tourUrl;

  @override
  State<FullscreenVirtualTour> createState() => _FullscreenVirtualTourState();
}

class _FullscreenVirtualTourState extends State<FullscreenVirtualTour> {
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewPaddingOf(context);
    final topOffset =
        (viewInsets.top > 0 ? viewInsets.top : AppSpacing.lg) + AppSpacing.sm;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_failed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: Text(
                    'Tour no disponible',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyReading.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              )
            else
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.tourUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  iframeAllowFullscreen: true,
                  iframeAllow:
                      'fullscreen; xr-spatial-tracking; gyroscope; accelerometer',
                  supportZoom: false,
                  useHybridComposition: true,
                  transparentBackground: false,
                ),
                onLoadStop: (_, _) {
                  if (!mounted) return;
                  setState(() => _ready = true);
                },
                onReceivedError: (_, _, _) {
                  if (!mounted) return;
                  setState(() => _failed = true);
                },
              ),
            if (!_ready && !_failed)
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
                ),
              ),
            Positioned(
              top: topOffset,
              right: AppSpacing.sm,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(
                    PhosphorIconsThin.x,
                    size: 20,
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
