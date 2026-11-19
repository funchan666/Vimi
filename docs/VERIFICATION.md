# Vimi verification · November 19, 2026

The current user request authorized runnable verification for this task. Android builds, emulator runs, focused tests and isolated hosted checks were executed. This supersedes the earlier source-only review; it does not establish a signed store release or a Google Play payment result.

## Environment and evidence

- Flutter 3.44 / Dart 3.12; Android emulator API 35, ARM64, serial `emulator-5554`. Its existing data was not wiped.
- Active-source analyzer: no issues. Recoverable historical source snapshots are excluded from analysis and application assets.
- Twenty-two focused widget/storage tests pass. They cover concurrent note saves, corrupt journal protection/recovery, account isolation, serialized drafts, practice create/reopen/edit/delete, publisher draft restoration/discard, comment focus during refresh, guest-readable child-safety policy, restricted-account deletion navigation, and 20 narrow/expanded secondary-page layouts at larger type.
- Hosted SQL transaction/rollback acceptance passes for consent/provisioning, content/social idempotency, approval/Storage authorization, mutual-follow IM, third-party RLS denial, unread/read persistence, private reports, blocks, client wallet-write denial, idempotent service credits/unlocks/reversals and reversal-debt settlement. All its fixtures roll back.
- Six earlier native acceptance suites, two history/continuity suites and the current Play-safety suite completed successfully at their recorded source snapshots; see `verification/2026-11-19/acceptance-summary.json`. They were not all rerun on the final AOT preview.
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

`dist/Vimi-1.0.0-arm64-preview.apk` is the recommended **36,522,345-byte** ARM64 profile preview. It uses the local Android debug certificate for preview installation; it is not an upload-signed store release. Signature scheme v2 verifies. The final preview was installed and cold-launched successfully on Android, and `play-final-preview.png` records the latest observed result. SHA-256 is in `artifacts.json`; earlier measurements are retained in the dated before-history/before-play records.

The native flows were verified with debug builds of their recorded source snapshots; the smaller profile preview has separate installation/startup evidence. A profile startup is not represented as repeating every interaction suite on an AOT binary.

Distributable APK contents were checked for all four distinct actual QA/operator/App-access passwords and private configuration files: none were found. Temporary local QA credentials were removed; the separate private operator and ordinary Play App-access credential files are retained, ignored and mode 0600. Hosted final state is **zero temporary users, posts, messages, reports, uploaded media and follows**, with **one fixed content operator**, **one ordinary maintained Play review account** and zero wallet balance. The email-test account was also deleted after recovery verification; the support/child-safety contact remains configured.

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
- `preview-artifact.json`: the current main-entrypoint artifact contains none of the four actual private passwords or fixture/config labels. The ordinary App access account has no moderator role or special feature behavior.
- `hosted-advisors-play.json`: no health findings, four intentional private-schema default-deny INFO notices, four small-dataset unused-index INFO notices, and the existing leaked-password-protection WARN. No plan change was made.
- `play-release-readiness.json` and `play-release-gate.log`: missing public URLs, publisher upload signing and disabled billing prevent a release build. A deliberately attempted configuration validation failed with the expected actionable messages. No release AAB, Play upload or real payment is implied.

The standard HTML policy pages are generated locally from the same bundled English text. Public publication is awaiting the user's audience decision; no public Site or working policy URL is claimed. No website browser visual check or cross-country reachability result is claimed. Read `GOOGLE_PLAY_READINESS.md`, `GOOGLE_PLAY_APP_ACCESS.md`, `GOOGLE_PLAY_DATA_SAFETY.md` and `CHILD_SAFETY_OPERATIONS.md` for the remaining publisher and operating requirements. None of these checks guarantees Google approval or protects an unrelated developer-account history.
