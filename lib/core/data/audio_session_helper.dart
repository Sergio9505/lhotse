import 'dart:io' show Platform;

import 'package:flutter/services.dart';

const _channel = MethodChannel('com.lhotsegroup.lhotse/audio_session');

/// Downgrade the iOS `AVAudioSession.category` to `.ambient`.
///
/// The `video_player_avfoundation` plugin upgrades the session category to
/// `.playback` on every `play()` of any video and never downgrades. While
/// the category stays at `.playback`, iOS treats the app as a "media app"
/// and keeps the screen on indefinitely — even with no AVPlayer rendering.
///
/// Call this:
/// - After each `controller.play()` in inline/decorative video contexts
///   (splash, welcome, hero) so the muted video plays without locking the
///   screen.
/// - After each `controller.dispose()` so any leftover playback context is
///   released.
///
/// Do NOT call from `FullscreenVideoPlayer._init()` — there we WANT
/// `.playback` so iOS keeps the screen alive while the user watches with
/// audio. Only call from its `dispose()` to reset on close.
///
/// The native handler lives in `ios/Runner/AppDelegate.swift`. Android no-op
/// — the bug is iOS-specific (Android `video_player` uses ExoPlayer and
/// does not touch screen-on state).
Future<void> downgradeAudioSessionToAmbient() async {
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod<void>('resetToAmbient');
  } catch (_) {
    // Best-effort. If the channel is unregistered the call throws
    // `MissingPluginException`; swallow because nothing depends on the
    // result and we don't want to crash the app over a UX nicety.
  }
}

/// Upgrade the iOS `AVAudioSession.category` to `.playback`.
///
/// Required when entering `FullscreenVideoPlayer`: inline plays downgrade
/// the session to `.ambient` for screen-sleep reasons, so the global state
/// is `.ambient` by the time the user taps to fullscreen. The plugin only
/// sets `.playback` once at registration time — later `play()`s do not
/// re-raise it — so without this explicit upgrade, fullscreen audio is
/// silenced by the iPhone's silent switch.
///
/// Symmetric to [downgradeAudioSessionToAmbient], which restores `.ambient`
/// on the fullscreen player's dispose.
Future<void> upgradeAudioSessionToPlayback() async {
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod<void>('setToPlayback');
  } catch (_) {
    // Best-effort, same rationale as the downgrade above.
  }
}
