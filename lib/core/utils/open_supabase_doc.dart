import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router.dart';

/// Downloads a Supabase document to the local cache and opens it in the
/// in-app [DocumentPreviewScreen].
///
/// [fileUrl] may be:
/// - A fully qualified URL (`https://…`) — used directly to download.
/// - A Supabase Storage path — converted to a 60 s signed URL before download.
///
/// [fileName] is the human display title shown in the preview header (e.g.
/// "Contrato Renta Fija"). It is NOT used to derive the file extension.
/// The extension is derived from [fileUrl] (reliable: every real URL in the
/// DB carries it). Content-Type header is the last-resort fallback.
///
/// [docId] is the cache key — same document is never downloaded twice per
/// session until the OS evicts the temp directory.
Future<void> openSupabaseDoc(
  BuildContext context, {
  required String fileUrl,
  required String fileName,
  required String docId,
  String bucketName = 'documents',
  String? subtitle,
  bool replace = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    // 1. Resolve to a downloadable URL.
    final downloadUrl = fileUrl.startsWith('http')
        ? fileUrl
        : await Supabase.instance.client.storage
            .from(bucketName)
            .createSignedUrl(fileUrl, 60);

    // 2. Derive extension from URL first — 100 % reliable for seed + uploads.
    String ext = _extensionFromUrl(fileUrl);

    final tempDir = await getTemporaryDirectory();

    // 3. Cache hit: if ext is known we can check before downloading.
    if (ext.isNotEmpty) {
      final cached = File('${tempDir.path}/$docId$ext');
      if (await cached.exists()) {
        if (!context.mounted) return;
        return _push(context, cached.path, fileName, subtitle, replace: replace);
      }
    }

    // 4. Download.
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    // 5. Last resort: derive extension from Content-Type if URL lacked it.
    if (ext.isEmpty) {
      ext = _extensionFromContentType(response.headers['content-type']);
    }

    final localPath = '${tempDir.path}/$docId$ext';
    await File(localPath).writeAsBytes(response.bodyBytes);

    if (!context.mounted) return;
    _push(context, localPath, fileName, subtitle, replace: replace);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Error al cargar el documento: $e')),
    );
  }
}

void _push(
  BuildContext context,
  String localPath,
  String displayName,
  String? subtitle, {
  bool replace = false,
}) {
  final extra = (
    localPath: localPath,
    displayName: displayName,
    subtitle: subtitle,
  );
  if (replace) {
    context.pushReplacement(AppRoutes.documentPreview, extra: extra);
  } else {
    context.push(AppRoutes.documentPreview, extra: extra);
  }
}

String _extensionFromUrl(String url) {
  // Strip query string (signed URLs carry ?token=…)
  final qIndex = url.indexOf('?');
  final clean = qIndex >= 0 ? url.substring(0, qIndex) : url;
  final lastSlash = clean.lastIndexOf('/');
  final segment = lastSlash >= 0 ? clean.substring(lastSlash + 1) : clean;
  final dot = segment.lastIndexOf('.');
  if (dot < 0 || dot == segment.length - 1) return '';
  return segment.substring(dot);
}

String _extensionFromContentType(String? contentType) {
  if (contentType == null) return '';
  final mime = contentType.split(';').first.trim().toLowerCase();
  switch (mime) {
    case 'application/pdf':
      return '.pdf';
    case 'image/jpeg':
      return '.jpg';
    case 'image/png':
      return '.png';
    case 'image/heic':
      return '.heic';
    case 'image/webp':
      return '.webp';
    case 'application/msword':
      return '.doc';
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return '.docx';
    case 'application/vnd.ms-excel':
      return '.xls';
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return '.xlsx';
    default:
      return '';
  }
}
