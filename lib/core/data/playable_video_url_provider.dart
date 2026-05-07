import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves a raw video URL (as stored in DB) to a playable, signed URL.
///
/// Bunny Stream URLs (hostname starts with `vz-`) are signed server-side
/// via the `sign_video_url` Edge Function (TTL 1 h). Supabase Storage
/// relative paths are signed with `createSignedUrl`. Other HTTPS URLs pass
/// through unchanged.
///
/// Use `valueOrNull` at call-sites — video is decoration, not primary content.
final playableVideoUrlProvider =
    FutureProvider.family.autoDispose<String, String>((ref, raw) async {
  if (raw.isEmpty) return raw;

  if (raw.startsWith('https://vz-')) {
    final res = await Supabase.instance.client.functions.invoke(
      'sign_video_url',
      body: {'url': raw},
    );
    if (res.status != 200) {
      throw Exception('sign_video_url failed: ${res.status}');
    }
    return (res.data as Map<String, dynamic>)['url'] as String;
  }

  if (raw.startsWith('http')) {
    return raw;
  }

  // Relative path → Supabase Storage private bucket `project-videos`.
  return Supabase.instance.client.storage
      .from('project-videos')
      .createSignedUrl(raw, 3600);
});
