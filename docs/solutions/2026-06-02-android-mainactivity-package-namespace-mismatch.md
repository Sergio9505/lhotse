---
date: 2026-06-02
tags: [android, release, manifest, gradle, crash, classnotfound]
related_adrs: []
---

# Android app crashes on launch — MainActivity package ≠ namespace (ClassNotFoundException)

## Symptom
The `.aab` uploaded to Play Console internal testing installed fine but **crashed
immediately on open**. Logcat:
```
java.lang.RuntimeException: Unable to instantiate activity
  ComponentInfo{com.lhotsegroup.lhotseapp/com.lhotsegroup.lhotseapp.MainActivity}:
java.lang.ClassNotFoundException: Didn't find class "com.lhotsegroup.lhotseapp.MainActivity"
```
Never seen before because the app had only ever been run on iOS — this `.aab` was the
first time the app actually executed on Android (debug or release).

## Diagnosis
`AndroidManifest.xml` declares `<activity android:name=".MainActivity" ...>`. The leading
`.` resolves **relative to the module `namespace`** (AGP 8+), so Android tried to
instantiate `com.lhotsegroup.lhotseapp.MainActivity`.

But the Kotlin class lived in a different package:
- `android/app/src/main/kotlin/com/lhotsegroup/lhotse/MainActivity.kt` → `package com.lhotsegroup.lhotse`
- `android/app/build.gradle.kts` → `namespace = "com.lhotsegroup.lhotseapp"`

`lhotse` ≠ `lhotseapp` → the class the manifest pointed at didn't exist → crash on every
launch (debug *and* release). The mismatch existed since the first commit; the namespace
was even renamed once (`com.lhotsegroup.app` → `com.lhotsegroup.lhotseapp`, commit `440dcfe`)
without ever moving `MainActivity`. It only surfaced now because Android was never run.

Compilation never complained — the class is valid Kotlin; the reference is only resolved at
runtime by the Android class loader.

## Fix
Aligned the `MainActivity` package with the `namespace` (Flutter-standard layout):
- Moved `kotlin/com/lhotsegroup/lhotse/MainActivity.kt` → `kotlin/com/lhotsegroup/lhotseapp/MainActivity.kt`
- Changed the declaration to `package com.lhotsegroup.lhotseapp`
- Manifest left untouched (`.MainActivity` now resolves correctly).

The Kotlin package of `MainActivity` is internal — Play Store identity is fixed by
`applicationId` (unchanged), so the move is safe. Verified on an Android emulator
(`flutter run --release`): no `ClassNotFoundException`, app reaches Welcome, Supabase data
loads. Bumped `pubspec.yaml` to `1.0.1+17` for the re-upload (`+16` was already consumed).

## Lesson
`android:name=".Foo"` is resolved against the Gradle `namespace`, not the directory the
file happens to sit in. If the activity's Kotlin/Java package doesn't match the namespace,
the app crashes at launch with `ClassNotFoundException` — and nothing catches it until the
app actually runs on Android.

## How to avoid next time
- When changing `namespace`/`applicationId`, move `MainActivity` (and any other manifest-
  referenced class) into a package that matches, or fully-qualify `android:name` in the
  manifest.
- Smoke-test a release build on an Android emulator (`flutter run --release -d <android>`)
  **before** uploading any `.aab` to a testing track — iOS-only testing will never expose
  Android-only manifest/class wiring bugs.
