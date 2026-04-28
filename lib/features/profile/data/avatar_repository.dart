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
  final session = client.auth.currentSession;
  final uid = session?.user.id;
  if (uid == null) {
    throw StateError('Cannot upload avatar: no authenticated user');
  }

  // Defensive refresh — if the JWT is missing/expired, supabase-storage will
  // accept the request as anon and fail the RLS policy with a misleading
  // "row violates RLS" 403 instead of "JWT expired".
  if (session?.isExpired ?? false) {
    developer.log('refreshing expired session before avatar upload',
        name: 'AvatarRepository');
    await client.auth.refreshSession();
  }

  final refreshed = client.auth.currentSession;
  developer.log(
    'avatar upload: uid=$uid '
    'token=${refreshed?.accessToken.substring(0, 20)}… '
    'expiresAt=${refreshed?.expiresAt} '
    'sessionPresent=${refreshed != null}',
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
