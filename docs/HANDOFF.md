# Vimi handoff

## Current result

Flutter Android application, English interface, neon-gradient dance-social visual system and Supabase deployment. The runtime community uses actual Supabase data. Explicitly labelled temporary QA actors were used and then removed. No permanent seed members, scripted replies, auto-follows or manufactured engagement remain. Original generated brand photographs are editorial app imagery. All 55 publisher-supplied photos and ten complete videos are optimized and served from the public Supabase publisher library, with publisher-confirmed commercial/likeness/audio rights. Their people are not seeded as members. See `media/SUPPLIED_MEDIA.md`.

Core source starts at `lib/main.dart`; screens are grouped under `lib/features`, data contracts in `lib/core`, visual components in `lib/design/vimi_ui.dart`. Dependencies and their lockfile are present. The four main destinations are Floor, Studio, Inbox and Me, now shown as icon-only navigation with long-press and accessible labels. Player/profile/publisher utilities use original glyphs; settings and libraries use clickable destination rows. Only Android is targeted.

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
| Moderation | Independent fixed operator created and native sign-in verified. Child-safety filtering and actual content/media removal are verified. Credentials: private config/reviewer-access.json. |
| App access | Ordinary reusable review login prepared in private config/play-review-access.json; no moderator role. See GOOGLE_PLAY_APP_ACCESS.md. |
| Support/legal | Support and child-safety contact: funchan7777777@gmail.com. English bundled policies and matching standard HTML pages are ready. Publisher identity, jurisdiction and public URL publication remain required before release. |
| Android upload signing | Supply your upload keystore and local key.properties |
| Runtime and store acceptance | Android debug/emulator and focused live-service checks performed; see VERIFICATION.md. No signed store release or Play transaction. |

The build configuration lives in ignored `config/app.json`; copy `config/app.example.json` when moving to another machine and supply this project's publishable key. Do not put privileged keys in the client. The project identity `com.vimistudio.vimi` must stay the same in Gradle, Play and verification code.

Practice journal/video copies, saved library selections and drill progress stay on the current device/account. Bundled reference clips are reused by note references, without copying the video again. Social and wallet data live in Supabase; a library profile image uploads only after explicit profile save. This version does not claim cross-device practice synchronization, end-to-end encrypted messaging, a standalone music catalogue, live audio/video calls or automated AI dance scoring.

## Checks actually performed

Active-source analysis, Android debug/profile compilation/install/run, twenty-two focused widget/storage tests, hosted SQL transaction/rollback invariants, real email/PKCE signup, direct signup, actual native Storage upload, two-account Realtime messaging/read receipts, independent fixed-reviewer sign-in, child-safety report filtering and suspended-account deletion were exercised. Actual harmless-fixture API checks cover permanent content/media removal, profile clearing and ordinary-member denial. Additional journey results, screenshots and limitations are in `VERIFICATION.md` and `verification/2026-11-19/`.

Use the independent reviewer credentials from `config/reviewer-access.json` in the normal Sign in page, then Me → Settings → Content review. The file is ignored by Git and has mode 0600; its password is never part of the distributable app configuration. The support email is a separate contact, not a moderator login.

## Installable preview

Use `dist/Vimi-1.0.0-arm64-preview.apk` (36.9 MB, profile mode, local test signature), with all 65 supplied source items available online and no bundled publisher media copies. It was installed and cold-launched successfully; all source-native journey evidence is in VERIFICATION.md. Earlier artifact metadata is retained under before-history/before-play/before-media/before-controls/before-cloud-library verification records. These APK files are ignored by Git.

Current supplied-media acceptance: all 55 full images decode on Android, all ten bundled videos initialize and advance playback, saved filtering and practice-note save/reopen pass, actual selected-avatar upload/download hashes match, and a focused native check confirms a rendered network avatar frame. Both temporary actors and their uploaded images were deleted; hosted Auth retains only the fixed content operator and ordinary App access account. All 128 runtime media files and bundled policies match the delivered APK byte for byte. Media shrank from 54.0 MB to 30.3 MB; complete content and quality were retained ahead of the 50 MB soft APK goal.

Ordinary users create their own account and enter immediately without email verification. Existing passwords remain required. The provided support email was used only as a temporary email/recovery fixture and has been removed from Auth; it is not a moderator account.

After acceptance the hosted project has one fixed content operator and one ordinary reusable Play App access account, no temporary QA accounts/content/media/follows, and no test coin credits. No paid Play transaction or production release was performed.

Read `GOOGLE_PLAY_READINESS.md`, `GOOGLE_PLAY_DATA_SAFETY.md` and `CHILD_SAFETY_OPERATIONS.md` before submission. Release builds now reject missing public policy URLs, signing/backend/contact configuration or disabled billing. This is a configuration guard, not a Google approval promise. The local HTML policies are in `policy-site/dist`; no public Site or policy URL is claimed until publication and an unauthenticated HTTP check complete.

The latest media-migration evidence is `verification/2026-11-19/cloud-library/`: all 128 downloads hash-verified, all 55 full portraits decoded and ten clips streamed on Android, legacy notes retained, real library-to-profile save and temporary account deletion passed. The import write policy is closed; normal clients cannot add or change public library content. Original and optimized project media backups were subsequently deleted at the publisher’s explicit request. Library viewing needs internet. The current artifact is 36,909,069 bytes; the prior bundled artifact was 67,253,150 bytes.
