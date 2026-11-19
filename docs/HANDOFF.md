# Vimi handoff

## Current result

Flutter Android application, English interface, neon-gradient dance-social visual system and Supabase deployment. The runtime community uses actual Supabase data. Explicitly labelled temporary QA actors were used and then removed. No permanent seed members, scripted replies, auto-follows or manufactured engagement remain. Included generated photographic assets are editorial app imagery, not claimed to depict registered members. No copyrighted K-pop music or cover videos were downloaded.

Core source starts at `lib/main.dart`; screens are grouped under `lib/features`, data contracts in `lib/core`, visual components in `lib/design/vimi_ui.dart`. Dependencies and their lockfile are present. The four main destinations are Floor, Studio, Inbox and Me. Only Android is targeted.

## Publisher inputs/configuration before release

| Item | Status / next step |
| --- | --- |
| App name, English, Flutter, Android, dance theme | Applied as Vimi |
| Supabase account/organization | User confirmed Primary and its organization; project created |
| Hosted database, private bucket, functions | Deployed; definition/configuration reads completed |
| Auth | Native redirects saved; signup email confirmation disabled as requested. Production recovery SMTP remains publisher setup. |
| Google Play products | Create the seven IDs in GOOGLE_PLAY_PRODUCTS.md |
| Google Play verifier credential | Configure server secret; it has not been supplied |
| Billing | Implemented but disabled until Play/backend setup and validation |
| Moderation | Independent fixed operator created and native sign-in verified. Credentials: private config/reviewer-access.json. |
| Support/legal | Support is funchan7777777@gmail.com and is synchronized in bundled policies. Publisher identity, jurisdiction and public URLs remain required before release. |
| Android upload signing | Supply your upload keystore and local key.properties |
| Runtime and store acceptance | Android debug/emulator and focused live-service checks performed; see VERIFICATION.md. No signed store release or Play transaction. |

The build configuration lives in ignored `config/app.json`; copy `config/app.example.json` when moving to another machine and supply this project's publishable key. Do not put privileged keys in the client. The project identity `com.vimistudio.vimi` must stay the same in Gradle, Play and verification code.

Practice journal/video copies and drill progress stay on the current device/account. Social and wallet data live in Supabase. This version does not claim cross-device practice synchronization, end-to-end encrypted messaging, licensed music, live audio/video calls or automated AI dance scoring.

## Checks actually performed

Active-source analysis, Android debug compilation/install/run, eleven focused widget/storage tests, hosted SQL transaction/rollback invariants, real email/PKCE signup, direct signup, actual native Storage upload, two-account Realtime messaging/read receipts, and independent fixed-reviewer sign-in were exercised. Additional journey results, screenshots and limitations are in `VERIFICATION.md` and `verification/2026-11-19/`.

Use the independent reviewer credentials from `config/reviewer-access.json` in the normal Sign in page, then Me → Settings → Content review. The file is ignored by Git and has mode 0600; its password is never part of the distributable app configuration. The support email is a separate contact, not a moderator login.

## Installable preview

Use `dist/Vimi-1.0.0-arm64-preview.apk` (36.6 MB, profile mode, local test signature). It was installed and cold-launched successfully; all source-native journey evidence is in VERIFICATION.md. Debug ARM64 and universal alternatives are also in dist. These files are ignored by Git.

Ordinary users create their own account and enter immediately without email verification. Existing passwords remain required. The provided support email was used only as a temporary email/recovery fixture and has been removed from Auth; it is not a moderator account.

After acceptance the hosted project has one fixed reviewer, no QA accounts/content/media/follows, and no test coin credits. No paid Play transaction or production release was performed.
