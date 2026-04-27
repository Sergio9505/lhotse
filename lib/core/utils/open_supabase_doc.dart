import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opens a document stored in Supabase (or hosted at a public URL) using
/// the OS-native viewer (Quick Look on iOS, `Intent.ACTION_VIEW` on
/// Android). Both platforms expose a native share sheet from the viewer
/// (Save to Files, Mail, Print, Markup on iOS; system share / open-with
/// on Android), so we don't render a custom in-app share UI.
///
/// `fileUrl` may be either:
/// - A fully qualified URL (`https://...`) — used directly to download.
/// - A Supabase Storage path (`bucket/path/to/file.pdf` or just
///   `path/to/file.pdf` if [bucketName] is provided) — converted to a
///   signed URL with a 60s TTL before download.
///
/// `docId` is used as the cache key so the same document doesn't get
/// re-downloaded on each tap. The cache lives in `getTemporaryDirectory()`
/// which iOS/Android may evict at their discretion.
Future<void> openSupabaseDoc(
  BuildContext context, {
  required String fileUrl,
  required String fileName,
  required String docId,
  String bucketName = 'documents',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    // 1. Resolve to a downloadable URL.
    final downloadUrl = fileUrl.startsWith('http')
        ? fileUrl
        : await Supabase.instance.client.storage
            .from(bucketName)
            .createSignedUrl(fileUrl, 60);

    // 2. Cache lookup — skip download if already on disk.
    final tempDir = await getTemporaryDirectory();
    final ext = _extensionFromFilename(fileName);
    final localPath = '${tempDir.path}/$docId$ext';
    final file = File(localPath);

    if (!await file.exists()) {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      await file.writeAsBytes(response.bodyBytes);
    }

    // 3. Open with system viewer — Quick Look on iOS, Intent.ACTION_VIEW
    //    on Android. Both surface their own native share sheet.
    final result = await OpenFilex.open(localPath);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo abrir el documento: ${result.message}')),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Error al cargar el documento: $e')),
    );
  }
}

String _extensionFromFilename(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot);
}

