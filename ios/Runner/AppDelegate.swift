import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Method channel for downgrading the shared `AVAudioSession` category
    // back to `.ambient` after a video play() call. The
    // `video_player_avfoundation` plugin upgrades the category to `.playback`
    // on every `play()` and never downgrades, which makes iOS treat the app
    // as a "media app" and keeps the screen alive even on screens without
    // active video rendering. The Dart helper at
    // `lib/core/data/audio_session_helper.dart` calls into this from each
    // video controller's play() and dispose() so the session stays at
    // `.ambient` whenever we're not actively viewing video in fullscreen.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.lhotsegroup.lhotse/audio_session",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "resetToAmbient":
          try? AVAudioSession.sharedInstance().setCategory(.ambient)
          result(nil)
        case "setToPlayback":
          // Fullscreen viewer raises the category back to `.playback` so iOS
          // emits audio even with the silent switch on and keeps the screen
          // alive while the user is watching. The dispose path resets to
          // `.ambient` to let the screen sleep on the underlying screens.
          try? AVAudioSession.sharedInstance().setCategory(.playback)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
