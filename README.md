# Vimi

English Flutter/Dart Android dance community. Project package: `com.vimistudio.vimi`. Local branch: `codex/vimi-flutter-android`.

## Included

- Neon-gradient Vimi icon and controls, dark violet surfaces, two original neon-lit photographic dance assets, 32 original raster utility glyphs and locally bundled DM Sans.
- Floor: approved photo/video posts, style filters, dancer discovery, three original choreography challenges, publishing from the gallery/camera, comments, edits, likes, saves, reports and blocks.
- Studio: a persistent private rehearsal journal, retained personal videos, playback speed/mirror/loop/seek, and three concrete coin-unlocked planning packs.
- Inbox: real Supabase messages after mutual following, unread/read states, draft persistence and reports. No fabricated conversations or followers.
- Me: profile editing and avatar capture, relationship lists, own posts/review states, saved work, coin wallet, policies, sign-out and account deletion.
- Supabase schema, private Storage and four deployed Edge Functions for purchase verification, account deletion, moderation and refund reconciliation.

Current [neon visual reference](docs/design-preview/vimi-neon-floor-v3-concept.png) is generated with illustrative member data, not an app screenshot. See [the handoff](docs/HANDOFF.md), [Google Play products](docs/GOOGLE_PLAY_PRODUCTS.md), [backend operations](docs/BACKEND.md) and [runtime verification](docs/VERIFICATION.md).

## Configuration

The local ignored `config/app.json` contains the new project's URL and **publishable** key. The app uses `--dart-define-from-file=config/app.json`. No service key or Play private key belongs in that file or the APK.

Set `VIMI_PREVIEW_ENGAGEMENT` to `true` for a debug or profile build to show labeled sample counts and comments on the publisher clips. Release builds always use actual activity. Reporting a sample hides it on the current device. Member comments, likes and reports use the signed-in Supabase account.

Only Android was generated. Installed toolchain inspected: Flutter 3.44.0 / Dart 3.12.0, Java 17 source target, compile/target Android SDK 36, minimum SDK 24. Dependencies are pinned in `pubspec.yaml` and resolved in `pubspec.lock`. Supabase Flutter remains on the inspected v2 API, not the newly incompatible v3.

Development commands:

```sh
flutter run --dart-define-from-file=config/app.json
flutter build appbundle --release --dart-define-from-file=config/app.json
```

Release signing requires `android/key.properties` based on `android/key.properties.example` and your upload key. Release is never silently signed with a debug key. No upload key has been generated.

## Verification and delivery

Android debug builds, analyzer, focused storage/widget tests and live Android/Supabase journeys were executed for the user's requested runnable verification. See `docs/VERIFICATION.md` for evidence and the exact remaining boundaries. Generated design concepts remain separate from actual emulator screenshots.

Production release signing, Google Play products/service credentials and real Play license-test purchases remain publisher setup. Billing stays visibly unavailable until they are configured. Production recovery-email delivery and public legal/operator details also require publisher configuration. No store upload or production release was made.

The support email is `funchan7777777@gmail.com`; the separate content-review login is kept in private `config/reviewer-access.json`. Ordinary signup no longer waits for email confirmation; existing passwords are verified. No commercial music is bundled and no automatic follows or fictional engagement is generated.

The installable ARM64 preview is `dist/Vimi-1.0.0-arm64-preview.apk` (36.6 MB, local test signature). The source-native suites and final profile startup have separate evidence in `docs/VERIFICATION.md`.
