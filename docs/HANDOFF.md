# Vimi handoff

## Current result

Flutter Android application, English interface, neon-gradient dance-social visual system and Supabase deployment. The runtime community uses actual Supabase data. Explicitly labelled temporary QA actors were used and then removed. No permanent seed members, scripted replies, auto-follows or manufactured engagement remain. Original generated brand photographs are editorial app imagery. All 55 publisher-supplied photos and ten complete videos are optimized and served from the public Supabase publisher library, with publisher-confirmed commercial/likeness/audio rights. Their people are not seeded as members. See `media/SUPPLIED_MEDIA.md`.

Core source starts at `lib/main.dart`; screens are grouped under `lib/features`, data contracts in `lib/core`, visual components in `lib/design/vimi_ui.dart`. Dependencies and their lockfile are present. The four main destinations are Floor, Studio, Inbox and Me, now shown as icon-only navigation with long-press and accessible labels. Player/profile/publisher utilities use original glyphs; settings and libraries use clickable destination rows. Only Android is targeted.

The November 20 welcome redesign replaces the generated welcome people with actual publisher group/duet covers, a working duet-preview route and one main registration action. Sign-in and legal links use a lighter hierarchy. Its Android interaction results and installed-preview captures are in `verification/2026-11-20/welcome/`. The signed-in community refresh gives Floor a media mosaic, first-screen rehearsal clips in Studio, a mutual-follow conversation chooser in Inbox and a real photo library in Me.

## Publisher inputs/configuration before release

| Item | Status / next step |
| --- | --- |
| App name, English, Flutter, Android, dance theme | Applied as Vimi |
| Supabase account/organization | User confirmed Primary and its organization; project created |
| Hosted database, private bucket, functions | Deployed; definition/configuration reads completed |
| Auth | Native redirects saved; signup email confirmation disabled as requested. Production recovery SMTP remains publisher setup. |
| App pricing | Free, including all three practice plans |
| Release application ID | `com.vimistudio.covercrew`, selected before the first upload |
| Moderation | Independent fixed operator created and native sign-in verified. Child-safety filtering and actual content/media removal are verified. Credentials: private config/reviewer-access.json. |
| App access | Ordinary reusable review login prepared in private config/play-review-access.json; no moderator role. See GOOGLE_PLAY_APP_ACCESS.md. |
| Support/legal | The English policies are live at [Vimi](https://vimi-dance.pages.dev/) and match the bundled text. Support and child-safety email: funchan7777777@gmail.com. The designated child-safety contact name is pending before submission. |
| Play Console | Start with the [internal test](GOOGLE_PLAY_FORM_GUIDE.md#0-先做内部测试). Then complete the app setup and run the 12-person closed test before applying for production access. |
| Android upload signing | Supply your upload keystore and local key.properties |
| Runtime and store acceptance | Prior Android and live-service checks are in VERIFICATION.md. The free revision requires its own build and install. |

The build configuration lives in ignored `config/app.json`. Copy `config/app.example.json` when moving to another machine and supply this project's publishable key. Keep privileged keys outside client configuration. The package in Play must match Gradle's application ID. The separately configured Supabase Auth callback is documented in [BACKEND.md](BACKEND.md).

Practice notes, retained videos, saved library selections and checklist progress stay on the current device and account. Reference videos use stable cloud references. Supabase stores the account and social data. A library profile image uploads after explicitly saving the profile. Voice and video calls use WebRTC between eligible mutual follows while the app is open.

## Checks actually performed

Active-source analysis, Android debug/profile compilation/install/run and 26 focused widget/storage tests passed for the November 20 welcome revision; its route suite also verified cloud-cover decoding, duet play/pause and guest-accessible entry/legal routes. Earlier hosted SQL invariants, real email/PKCE signup, direct signup, native Storage upload, two-account Realtime messaging/read receipts, independent reviewer sign-in, child-safety filtering and account deletion retain their recorded November 19 evidence. Additional results, screenshots and limitations are in `VERIFICATION.md` and the dated verification directories.

Use the independent reviewer credentials from `config/reviewer-access.json` in the normal Sign in page, then Me → Settings → Content review. The file is ignored by Git and has mode 0600; its password is never part of the distributable app configuration. The support email is a separate contact, not a moderator login.

## Previous Android preview

The old locally signed preview APK was removed during release preparation. Its screenshots and native route evidence are in `verification/2026-11-20/community-refresh/`.

November 19 supplied-media acceptance decoded all 55 full images on Android, streamed all ten videos, reopened saved filters/practice notes, matched actual avatar upload/download hashes and confirmed a rendered network avatar frame. Both temporary actors and their uploads were deleted. All 128 hosted publisher objects were hash-verified before their local package copies were removed. Optimized media totals 30.3 MB, compared with 54.0 MB before compression, with all source items retained online.

Ordinary users create their own account and enter immediately without email verification. Existing passwords remain required. The provided support email was used only as a temporary email/recovery fixture and has been removed from Auth; it is not a moderator account.

After acceptance the hosted project has one fixed content operator and one ordinary reusable Play App access account, no temporary QA accounts/content/media/follows, and no test coin credits. No paid Play transaction or production release was performed.

Read `GOOGLE_PLAY_READINESS.md`, `GOOGLE_PLAY_DATA_SAFETY.md` and `CHILD_SAFETY_OPERATIONS.md` before submission. Release builds require public policy URLs, backend and contact configuration, and upload signing. The local HTML in `policy-site/dist` matches the pages verified without a login on the production host.

The media-migration evidence is `verification/2026-11-19/cloud-library/`: all 128 downloads hash-verified, all 55 full portraits decoded and ten clips streamed on Android, legacy notes retained, real library-to-profile save and temporary account deletion passed. The import write policy is closed. Original and optimized project media backups were subsequently deleted at the publisher’s explicit request. Library viewing needs internet.
