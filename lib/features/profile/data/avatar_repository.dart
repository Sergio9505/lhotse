import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_provider.dart';

/// Uploads a new avatar to the `avatars` public bucket at a fixed path
/// `{uid}/avatar.jpg` (upsert — always replaces the previous image, so the
/// bucket never accumulates dead files).
///
/// After the upload succeeds, `user_profiles.avatar_url` is set to the
/// public URL with a `?v={millis}` cache-buster derived from `now()`, so the
/// Flutter `Image.network` cache invalidates the old copy on re-render.
///
/// Finally invalidates `currentUserProfileProvider` so the new URL propagates
/// to every widget watching the profile.
Future<void> uploadAvatar(WidgetRef ref, XFile file) async {
  final client = ref.read(supabaseClientProvider);

  // Always refresh before upload — eliminates the stale-JWT class of bugs:
  // refresh-token rotation, sign-out from another device, clock drift.
  // The conditional `if (isExpired)` guard is insufficient because the
  // client clock may consider the token valid while the server rejects it,
  // causing storage to evaluate the request as anon and fail the RLS INSERT.
  final AuthResponse refreshResp;
  try {
    refreshResp = await client.auth.refreshSession();
  } on AuthException catch (e) {
    throw StateError('Cannot upload avatar: session refresh failed (${e.message})');
  }
  final freshSession = refreshResp.session;
  if (freshSession == null) {
    throw StateError('Cannot upload avatar: no session after refresh');
  }

  final uid = freshSession.user.id;

  // Defensively propagate the refreshed token to the storage HTTP client.
  // supabase_flutter 2.x does this automatically, but being explicit
  // eliminates any cached-header regression.
  client.storage.headers['Authorization'] = 'Bearer ${freshSession.accessToken}';

  developer.log(
    'avatar upload: uid=$uid '
    'token=${freshSession.accessToken.substring(0, 20)}… '
    'expiresAt=${freshSession.expiresAt}',
    name: 'AvatarRepository',
  );

  final path = '$uid/avatar.jpg';
  final bytes = await File(file.path).readAsBytes();

  try {
    await client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
            cacheControl: '3600',
          ),
        );
  } on StorageException catch (e) {
    developer.log(
      'StorageException: statusCode=${e.statusCode} error=${e.error} '
      'message=${e.message}',
      name: 'AvatarRepository',
    );
    rethrow;
  }

  final publicUrl = client.storage.from('avatars').getPublicUrl(path);
  final busted = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

  await client
      .from('user_profiles')
      .update({'avatar_url': busted})
      .eq('id', uid);

  ref.invalidate(currentUserProfileProvider);
}
