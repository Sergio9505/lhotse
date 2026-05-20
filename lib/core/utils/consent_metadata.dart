import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

/// Audit metadata that travels with every consent event (signup +
/// subsequent grant/revoke). Used by `record_consent` RPC + the
/// `handle_new_user` trigger to populate `consent_log` for RGPD
/// accountability (Art. 5.2).
///
/// `device_model` (e.g. "iPhone 16 Pro") would need `device_info_plus`;
/// kept out of this helper for now since `platform + os_version + app_version`
/// already gives enough audit specificity. Add later if needed.
class ConsentMetadata {
  const ConsentMetadata({
    required this.platform,
    required this.osVersion,
    required this.appVersion,
  });

  final String platform;
  final String osVersion;
  final String appVersion;

  Map<String, dynamic> toMap() => {
        'platform': platform,
        'os_version': osVersion,
        'app_version': appVersion,
      };
}

Future<ConsentMetadata> collectConsentMetadata() async {
  final pkg = await PackageInfo.fromPlatform();
  return ConsentMetadata(
    platform: Platform.operatingSystem,
    osVersion: Platform.operatingSystemVersion,
    appVersion: '${pkg.version}+${pkg.buildNumber}',
  );
}
