import 'package:url_launcher/url_launcher.dart';

/// Lhotse's investor-relations WhatsApp line (E.164 without the `+`, as the
/// `wa.me` deep link requires). Single source of truth for the number.
const String kLhotseWhatsappNumber = '34614244939';

/// Opens WhatsApp (app if installed, else web) at [kLhotseWhatsappNumber] with
/// [message] pre-filled. Shared by every request CTA (project info, invest
/// info, VIP access) — each passes its own message. Returns whether the
/// external app/browser was launched so the caller can surface a fallback.
/// See ADR-92.
Future<bool> launchWhatsApp(String message) async {
  final uri = Uri.parse(
    'https://wa.me/$kLhotseWhatsappNumber?text=${Uri.encodeComponent(message)}',
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
