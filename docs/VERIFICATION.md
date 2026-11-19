# Vimi verification · November 19, 2026

The current user request authorized runnable verification for this task. Android builds, emulator runs, focused tests and isolated hosted checks were executed. This supersedes the earlier source-only review; it does not establish a signed store release or a Google Play payment result.

## Environment and evidence

- Flutter 3.44 / Dart 3.12; Android emulator API 35, ARM64, serial `emulator-5554`. Its existing data was not wiped.
- Active-source analyzer: no issues. Recoverable historical source snapshots are excluded from analysis and application assets.
- Twenty-six focused widget/storage tests pass. They cover concurrent note saves, corrupt journal protection/recovery, account isolation, serialized drafts, practice create/reopen/edit/delete, publisher draft restoration/discard, comment focus during refresh, guest-readable child-safety policy, restricted-account deletion navigation, icon-only navigation names/selection/click semantics, and 28 narrow/expanded secondary-page layouts at larger type, including media libraries, profile editing and settings. Three cloud-catalogue cases verify all IDs/resources, old note references and rejection of unsafe resource metadata.
- Hosted SQL transaction/rollback acceptance passes for consent/provisioning, content/social idempotency, approval/Storage authorization, mutual-follow IM, third-party RLS denial, unread/read persistence, private reports, blocks, client wallet-write denial, idempotent service credits/unlocks/reversals and reversal-debt settlement. All its fixtures roll back.
- Six earlier native acceptance suites, two history/continuity suites, the Play-safety suite and two current supplied-media/avatar suites completed successfully at their recorded source snapshots; see `verification/2026-11-19/acceptance-summary.json`. They were not all rerun on the final AOT preview.
- Actual native screenshots and local logs are under `verification/2026-11-19/`. Screenshots with QA names show explicitly labelled temporary fixtures, not seeded community content.

## Verified native and live-service results

| Journey | Observed result |
| --- | --- |
| Original signup email | A genuine Supabase confirmation email reached the provided Gmail; its genuine PKCE link returned to Android and established the session. Email confirmation was subsequently disabled at the user's explicit request. |
| Direct signup | A new real Auth user received an immediate native session without opening email. An incorrect password was rejected. |
| Password correction | A wrong password can be corrected on the same Android sign-in screen; the real account then signs in. Native IME synchronization is included in the driver. |
| Existing member and deletion | Correct-password native sign-in and the genuine account-deletion function passed; the temporary account was removed. |
| Independent fixed reviewer | The separate fixed operator signed in on Android and opened the server-protected review queue through Me → Settings. The support email has no moderator role. |
| Guest challenge continuation | Selecting Share your take as a guest, signing in, and returning to the selected challenge's publisher passed. |
| Native image publication | Android's genuine photo picker selected a labelled original QA image; real bytes uploaded to private Storage, the owner's post was pending, and another member could not access the pending post. |
| Mutual-follow messaging | Two authenticated actors exchanged real messages, received a live reply through Realtime, and the sender displayed the actual read receipt. |
| Post and profile changes | Approved visibility, saves/likes, a pending comment, editing back to pending review, and profile persistence were verified against actual server results. |
| Practice notes/video | Genuine Android video picker and 12-second decoder fixture; play/pause, speed, mirror, loop, full-screen pause, private-file retention, reopen and deletion passed. Returning from the picker retains the active guest studio. |
| Responsive Android | Actual display changed to 1600 × 1000 at density 160 with font scale 1.3; Studio adapted to its side navigation. Original 1080 × 2400 / density 420 / font 1.0 were restored. |
| Safety | Blocking removed messaging eligibility; unblocking did not restore follows. A real report hid its target, appeared in Your reports, and was resolved by the reviewer API. |
| Play safety | Child-safety standards opened without login, the actual reviewer queue filtered child-safety reports, and a suspended temporary member signed in and completed real account deletion on Android. |

Native per-journey result JSON files provide the concrete evidence. Earlier runs exposed both product defects and asynchronous test-driver timing issues; assertions that failed are not counted as a passing whole suite. Successful result files, the clean hosted state and remaining limits are recorded here and in the handoff.

## Defects repaired

- Missing policy-consent metadata could pass the server check because SQL NULL was not handled; the trigger now rejects it explicitly.
- Concurrent practice saves could overwrite another save; journal changes now read and merge inside a serialized queue.
- Draft writes could finish after submission/discard; queued writes/removal and stable request nonces prevent resurrection and duplicate retries.
- Returning from a system picker reset guest browsing; lifecycle refresh now preserves the active studio.
- Guest sign-in previously discarded the selected action; the route now resumes after real authentication.
- Refreshing post details could temporarily remove the comment editor; the loaded page and input focus now stay present during refresh.
- Photo dimensions arrived late and moved controls; image slots now reserve their layout space.
- A reviewer could tap approval before the image/video decoder was ready; post approval now waits for successful media loading.
- Review queues now include actual reported targets, tolerate missing media and reject updates of missing items instead of returning false success.
- Player retries release the old controller; progress caches tolerate invalid entries and serialize user changes.

## Explicit boundaries

- No Google Play products, service-account secret, upload key or store testing-track installation has been supplied. Billing stays disabled and truthful. SQL wallet checks are not payment tests.
- No release signing, AAB upload, public store listing or physical-device acceptance was performed. Debug artifacts are for direct local evaluation.
- Camera hardware capture, denied permissions, prolonged network outages and the full range of Android devices have not been exhaustively exercised.
- Production SMTP, general-user recovery-email delivery, publisher legal identity/jurisdiction and public policy URLs require publisher setup. The configured support address is real; legal identity and published URLs are not invented.
- Directory, relationships, feed/archive/saved/challenge posts, comments, Inbox, chat, reports, ledger and reviewer queues now use stable cursor pages with load-more and retry. Pagination removes the previous 30/100-row client cutoffs and the feed offset cap; no unbounded single-request or production load benchmark is claimed.
- No live calling, licensed K-pop catalog, AI dance scoring or cross-device private-practice synchronization is claimed.

See `BACKEND.md`, `GOOGLE_PLAY_PRODUCTS.md` and `HANDOFF.md` for operation and publisher configuration.

## Deliverable and cleanup

`dist/Vimi-1.0.0-arm64-preview.apk` is the recommended **36,909,069-byte** ARM64 profile preview with all 65 supplied source items served online and no bundled publisher media. It uses the local Android debug certificate for preview installation; it is not an upload-signed store release. Signature scheme v2 verifies. It was installed and cold-launched successfully on Android; `cloud-library/preview-cloud-player.png` is the current installed-preview capture; cold launch is recorded separately. SHA-256 is in `artifacts.json`; earlier measurements remain in the before-history/before-play/before-media/before-controls/before-cloud-library records.

The native flows were verified with debug builds of their recorded source snapshots; the smaller profile preview has separate installation/startup evidence. A profile startup is not represented as repeating every interaction suite on an AOT binary.

The current distributable APK was checked for three actual passwords (the two retained operator/App-access credentials and this pass’s disposable QA credential), private configurations and native-test labels: none were found. The disposable local credential was removed after scanning. The earlier media snapshot also checked its two additional temporary credentials before those private files were removed. Temporary local QA credentials were removed; the separate private operator and ordinary Play App-access credential files are retained, ignored and mode 0600. Hosted final state is **zero temporary users, posts, messages, reports, uploaded media and follows**, with **one fixed content operator**, **one ordinary maintained Play review account** and zero wallet balance. The email-test account was also deleted after recovery verification; the support/child-safety contact remains configured.

`test/fixtures/rehearsal-sample.mp4` is a 12-second still-photo decoder fixture, not sample choreography and not an application asset. The historical email-confirmation test is retained as `.dart.txt`; current signup acceptance uses `direct_registration_test.dart`.

## Additional comprehensive-history acceptance

The latest pass preserves the approved neon visual system and adds shared cursor paging and retries to the directory, relationships, post collections, comments, Inbox, chat, private reports, ledger and reviewer queues. Refresh keeps loaded history through its previous boundary, deduplicates timestamp ties and keeps existing content when a request fails. Queued refreshes and duplicate taps share work; responses from an old account or disposed page are discarded. Realtime messages refresh messaging views separately from social editors.

- `history/native-results.json`: real Android search/reset, both 32-person relation lists, 41-post archive and refresh depth, 61-comment history with an unsent draft, 127-message history plus an actual Realtime reply, 31 private reports, 31 zero-value QA ledger entries with balance unchanged, and 35-comment/31-report review queue pages and role denial.
- `continuity/native-results.json`: 32 real Inbox conversations across pages, genuine native video decoding, the same playback controller/position/speed/loop/mirror across full-screen transitions, changes retained on return and playback paused on navigation. The 12-second video remains a decoder fixture rather than choreography.
- `history-contract.json` / `supabase/tests/cursor_history.sql`: 137 posts, 241 messages and 29 Inbox conversations across timestamp/UUID pages with microsecond ties, unfollow history, block RLS, unrelated-account denial and restricted RPC grants; all database test fixtures roll back.
- `history-edge-checks.json`: actual moderator queue pages preserve microseconds and unique IDs; unsigned callers, ordinary members and malformed requests are denied.
- At the history pass, twenty focused local widget/storage tests and the active-source analyzer passed. Cases cover paging, arrivals, removed boundaries, failures/retry, queued refreshes, account switches/disposal, corrupt recovery envelopes and comment focus through failed refresh. The current Play pass adds two safety cases.

The comments editor stays mounted on long pages and retains the last successful post while a refresh fails. Photos have in-page retries and renewed signed URLs in their zoom view. A damaged recovery envelope no longer hides the remaining journal copies, and its original bytes remain available. Ledger history refreshes when the balance or reversal debt changes.

At the history pass, two genuine temporary member accounts were deleted using the authenticated deletion function; the remaining labelled directory fixtures and zero-value ledger rows were explicitly removed. Hosted counts then were zero QA actors, posts, messages, reports, media, follows and QA ledger rows, with one fixed reviewer. That APK was scanned against all three then-current actual QA/operator passwords and private fixture/config labels; none were present. Earlier debug artifact measurements are retained in `artifacts-before-history.json` and are not current delivery binaries.

The history pass's 36,517,075-byte preview was installed and cold-launched; its screenshot and advisory refresh remain historical evidence. The current artifact and startup are recorded above.

## Google Play safety pass

- `play-safety/native-results.json`: genuine Android guest policy access, child-safety report filtering and suspended-account deletion. The suspended actor was deleted through the native UI; its companion QA actor used the real authenticated deletion endpoint. No temporary accounts/content/media remain.
- `play-safety-backend.json`: actual harmless original photo, post, comment, message and profile fixtures verified report filtering, reported-avatar review URLs, permanent record/media removal, idempotent retries, suspension and ordinary-member/service-RPC denial. No illegal or child material was used.
- `play-sql-safety.json` / `supabase/tests/play_safety.sql`: hosted transaction/rollback contract, including active-owner media access, suspended-owner Storage denial, trusted moderator boundaries, permanent removal/profile clearing, one audit on retry, suspended reviewer denial and deletion-reference scrubbing.
- `play-provider-log-fields.json`: aggregate field/count evidence of actual IP-inferred city/country, TLS/client fingerprints and search parameters in provider logs. No personal log values were copied. Privacy text and the Data safety worksheet disclose this processing despite the absence of device location permission.
- `play-native-alignment.json`: the exact delivered APK targets API 36, has no broad gallery/contacts/location/all-files/AD_ID permission, and passes static ARM64 ELF and APK 16 KB alignment checks. An actual 16 KB runtime and final release AAB remain unverified. Bundled legal assets match source bytes.
- `preview-artifact.json`: the current main-entrypoint artifact contains none of the three actual passwords checked for this pass and no fixture/config labels. The ordinary App access account has no moderator role or special feature behavior.
- `hosted-advisors-play.json`: no health findings, four intentional private-schema default-deny INFO notices, four small-dataset unused-index INFO notices, and the existing leaked-password-protection WARN. No plan change was made.
- `play-release-readiness.json` and `play-release-gate.log`: missing public URLs, publisher upload signing and disabled billing prevent a release build. A deliberately attempted configuration validation failed with the expected actionable messages. No release AAB, Play upload or real payment is implied.

The standard HTML policy pages are generated locally from the same bundled English text. Public publication is awaiting the user's audience decision; no public Site or working policy URL is claimed. No website browser visual check or cross-country reachability result is claimed. Read `GOOGLE_PLAY_READINESS.md`, `GOOGLE_PLAY_APP_ACCESS.md`, `GOOGLE_PLAY_DATA_SAFETY.md` and `CHILD_SAFETY_OPERATIONS.md` for the remaining publisher and operating requirements. None of these checks guarantees Google approval or protects an unrelated developer-account history.

## Supplied-media acceptance · earlier bundled snapshot

This section records the earlier bundled delivery. The current cloud migration and removal are recorded below; its originals, compression results and rights evidence remain relevant.

- All 55 images and ten videos from the confirmed Downloads set are registered. The publisher confirmed commercial App distribution, likeness and existing audio rights. Full source/optimized/route mappings are in `media/SUPPLIED_MEDIA.md`; original files and byte-verified backups are retained outside app assets.
- Media fell from 54,009,823 to 30,324,892 bytes, including list thumbnails and genuine first-frame covers. Every video fully decodes, retains its frame count and exact normalized frame timestamps, and preserves all original AAC packet hashes. Five originals were already silent. Source/output image and first/middle/last video comparisons were inspected; compression is lossy.
- `supplied-media/native-results.json`: all 55 full images decode on Android, all ten bundled video controllers initialize and advance playback, saved filtering and asset-reference practice save/reopen pass, and selecting the last of 55 images performs a genuine upload whose downloaded bytes match the source asset hash.
- `supplied-avatar/native-results.json`: a second focused native journey waits for the saved avatar's network image frame, verifies its portrait bitmap and captures the actual rendered profile photo. The shared avatar now retains the original brand placeholder while a network image loads instead of leaving an empty circle.
- The first native attempt exposed the guest “Explore the studio” button landing on Floor; it now opens Studio. Subsequent driver failures involved returning to a retained grid scroll position before reaching its off-screen filters. The passing suite explicitly scrolls back to those filters; failed partial results are kept as diagnostic records and are not counted as successful suites.
- Both disposable actors completed real native account deletion. A fresh hosted count confirms two retained internal accounts, zero media QA users, zero uploaded objects, posts, messages and follows. Temporary local credential files were removed after scanning the current APK against all four actual private password values.
- `media-analyze.log` and `media-widget-tests.log`: analyzer has no issues; all 22 tests pass, with 24 narrow/expanded larger-text page cases. `media-profile-build.log` records the main-entrypoint profile build. A longer numeric label was given enough width in the practice editor.
- `media-apk-packaging.json`: all 128 distinct runtime media files, the catalogue and all bundled policies match source bytes in the delivered APK. API 36, min API 24, ARM64, scoped permissions and static 16 KB ELF/ZIP checks pass. Physical/16 KB devices, a signed AAB, actual Play payment and full AOT journey reruns remain separate unperformed checks.

The current 66.9 MB profile APK exceeds the 50 MB soft target because all complete supplied content is retained at readable quality. Source media is 43.9% smaller; the APK figure is measured separately. No store delivery size is inferred from either number.

## Compact controls and icon navigation · earlier bundled snapshot

The approved icon controls remain in the current app. The APK metrics and local guest suite in this section record the preceding bundled snapshot.

The November 19 UI refinement removes visible captions from bottom navigation and the expanded rail, replaces common utility text actions with original glyphs, and turns library/journal/wallet/settings/help destinations into clickable rows. Primary submission, save, purchase and destructive-confirmation labels remain explicit. All 55 images and ten videos remain packaged.

- `neon-controls/widget-tests.txt` and `analyze.txt`: 23 tests pass and the analyzer reports no issues. Four navigation labels, selected state, tap semantics and 48+ hit areas are checked in compact and expanded layouts; 28 secondary-page layout cases use 1.3× text.
- `neon-controls/native-results.json`: API-35 ARM64 verifies all four icon destinations; actual bundled-video decoding/playback; seek by five seconds and direct time entry; speed, loop and mirror; the shared controller through full-screen and return; the 55-image picker; the camera source sheet; settings/help/child-safety navigation. This focused suite uses a local guest controller with no server connection or account/content writes. Profile-edit imagery is explicitly a local UI fixture, and no profile save/upload was attempted in this pass. Camera capture, physical-device behavior, remote social/auth flows and real Play payments were not rerun.
- `neon-controls/verification.json`, `preview-startup.txt`, `preview-signature.txt` and `preview-studio.png`: current main-entrypoint profile APK, installed/cold-started separately from the debug interaction target. The final APK byte-matches all 128 runtime media files, the new original atlas and bundled policies; its ARM64 ELF loads and ZIP layout pass static 16 KB alignment checks. No 16 KB device result is implied. Only the two retained private passwords are available for this pass's credential scan.

The native acceptance screenshot `compact-rehearsal-controls.png` shows the complete preserved frame and the compact controls. No fictional community content was added, and no hosted moderation, auth or billing configuration changed in this UI pass.

## Current cloud-library delivery and local removal

The publisher explicitly selected migration of all 55 images and ten videos to Supabase, followed by removing their package copies after verification. The current main-entrypoint ARM64 preview is **36,909,069 bytes**, compared with **67,253,150 bytes** in `artifacts-before-cloud-library.json`. All 128 former content files and their four Flutter registrations were removed after verification. Original/optimized recovery copies are ignored outside the app assets. No additional image/video compression or audio modification occurred.

- `cloud-library/public-object-verification.json`: anonymous GET byte/hash matches for all 128 optimized files (30,324,892 bytes), correct MIME types and HTTP 206 ranges for all ten MP4s. The lightweight catalogue remains bundled; images and videos do not.
- `cloud-library/native/native-results.json`: API-35 ARM64 downloads/decodes all 55 portraits and streams all ten complete videos through actual native network controllers. It resolves a prior bundled asset reference, saves/reopens a cloud practice note and bookmark, downloads/selects the last portrait, saves it through the real private-avatar upload and compares the returned bytes. The actual native account-deletion flow removes that disposable actor and avatar. A transient TLS termination in the first attempt led to bounded transport retries; the complete subsequent suite passed in about two minutes.
- `cloud-library/access-verification.json`: anonymous, ordinary-member and operator inserts into the publisher bucket are all denied after the import policy was removed. `dance-library` alone is public; member `dance-media` remains private. The live final count is 128 publisher objects, zero private member objects, zero temporary media actors, zero leftover test objects, and the two maintained internal accounts. The two migration files match the deployed publisher-library/import-closure history entries.
- `cloud-library/widget-tests.txt` / `analyze.txt`: 26 tests pass and analysis has no issues after the local media files were removed. Cases include every legacy clip reference and malicious URL/hash/size/type metadata; the previous 28 narrow/expanded larger-type layout cases remain.
- `cloud-library/apk-packaging.json`: no `assets/content/` files in the exact current APK. All bundled UI, data and policy files match source bytes. Main build, v2 signature, API/permission badging, ARM64 ELF load alignment and APK ZIP alignment are recorded. This is a local test-signed profile preview, not a release AAB or a Play payment result; a 16 KB runtime and physical device remain untested.
- `cloud-library/installed-preview-ui.json`: the installed main profile binary cold-launches, displays a retry glyph under a targeted emulator network denial, retries after connectivity restoration, and initializes the cloud video without bundled media. The emulator’s firewall was restored in a finally block. Offline/online/player screenshots were visually inspected. This separate profile check does not repeat every debug account flow.

Bundled privacy text, the matching local HTML and the Data safety worksheet now describe public publisher media delivery, network/provider logs and the need for internet. Local bookmarks remain references rather than offline downloads. Member uploads, private journals, billing and auth contracts retain their existing roles. The earlier security advisor notices remain: four intentional private-table default-deny INFO notices and the previously recorded leaked-password-protection WARN; performance reports four existing small-dataset unused-index INFO notices. No plan or auth setting changed. Public policy website publication, publisher signing and real Play product/payment acceptance remain the previously documented release work.

## Subsequent local backup cleanup

The publisher explicitly requested deletion of the project media backups after migration. `ProjectMaterials/Supplied` was removed: 196 files, 84,465,898 bytes, including 65 original copies, 128 optimized copies and three staging JSON files. Earlier preservation statements above describe their original verification snapshots; the current local state is recorded in `media/local-backup-cleanup.json`. Runtime code, the cloud catalogue, current APK and cloud objects were not changed. The old local preparation tool now refuses to recreate the backups while cloud delivery is active, and the migration helper performs read-only cloud verification without local files. No App build, tests or new cloud requests were needed for this local cleanup.
