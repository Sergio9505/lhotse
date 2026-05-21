import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

/// Embeds an external URL inside the app rather than redirecting to Safari /
/// Chrome. Used by:
/// - The three legal/support entries in Profile (terms, privacy, support) to
///   surface the canonical pages on `lhotsegroup.com` without yanking the
///   user out of the app shell.
/// - The bottom CTA of `NewsDetailScreen` when the news has no associated
///   project but has an `external_url` (e.g. World of Interiors article).
///
/// No title text in the chrome — the embedded page owns its own heading
/// (Apple Settings, Sotheby's, Robinhood and JPM Private Bank all keep
/// their in-app webviews chrome-light for the same reason; doubling the
/// page title in a native bar reads as redundancy and breaks the
/// editorial restraint of the wealth voice).
class EmbeddedWebViewScreen extends StatefulWidget {
  const EmbeddedWebViewScreen({super.key, required this.url});

  final String url;

  @override
  State<EmbeddedWebViewScreen> createState() => _EmbeddedWebViewScreenState();
}

class _EmbeddedWebViewScreenState extends State<EmbeddedWebViewScreen> {
  bool _ready = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Thin chrome — just the back chevron, no title. The embedded
          // page surfaces the heading itself.
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              topPadding + AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: const SizedBox(
              height: 44,
              child: Row(
                children: [LhotseBackButton.onSurface()],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_failed)
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        'Página no disponible',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyReading.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      supportZoom: true,
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
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
