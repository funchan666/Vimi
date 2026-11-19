# Vimi verification · November 19, 2026

The current user request authorized runnable verification for this task. Android builds, emulator runs, focused tests and isolated hosted checks were executed. This supersedes the earlier source-only review; it does not establish a signed store release or a Google Play payment result.

## Environment and evidence

- Flutter 3.44 / Dart 3.12; Android emulator API 35, ARM64, serial `emulator-5554`. Its existing data was not wiped.
- Active-source analyzer: no issues. Recoverable historical source snapshots are excluded from analysis and application assets.
- Eleven focused widget/storage tests pass. They cover concurrent note saves, corrupt journal protection/recovery, account isolation, serialized drafts, practice create/reopen/edit/delete, publisher draft restoration/discard, comment focus during refresh, and 20 narrow/expanded secondary-page layouts at larger type.
- Hosted SQL transaction/rollback acceptance passes for consent/provisioning, content/social idempotency, approval/Storage authorization, mutual-follow IM, third-party RLS denial, unread/read persistence, private reports, blocks, client wallet-write denial, idempotent service credits/unlocks/reversals and reversal-debt settlement. All its fixtures roll back.
- Six current native acceptance suites completed successfully; see `verification/2026-11-19/acceptance-summary.json`.
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
- Community/feed pagination exists; some relationship, comment, report, ledger and chat reads currently use documented bounded batches (30/100). Large-history pagination is not represented as unlimited.
- No live calling, licensed K-pop catalog, AI dance scoring or cross-device private-practice synchronization is claimed.

See `BACKEND.md`, `GOOGLE_PLAY_PRODUCTS.md` and `HANDOFF.md` for operation and publisher configuration.

## Deliverable and cleanup

`dist/Vimi-1.0.0-arm64-preview.apk` is the recommended **36,605,739-byte** ARM64 profile preview. It uses the local Android debug certificate for preview installation; it is not an upload-signed store release. Signature scheme v2 verifies. The final preview was installed and cold-launched successfully on Android, and `final-preview-welcome.png` records the observed result. SHA-256 and all debug alternatives are in `artifacts.json`.

The native flows were verified with debug builds of this source; the smaller profile preview has separate installation/startup evidence. A profile startup is not represented as repeating every interaction suite on an AOT binary.

Distributable APK contents were checked for the actual QA/operator passwords and private configuration files: none were found. Temporary local QA credentials were removed; only the separate private operator credential file is retained. Hosted final state is **zero temporary users, posts, messages, reports, uploaded media and follows**, with **one fixed reviewer** and zero wallet balance. The email-test account was also deleted after recovery verification; the support contact remains configured.

`test/fixtures/rehearsal-sample.mp4` is a 12-second still-photo decoder fixture, not sample choreography and not an application asset. The historical email-confirmation test is retained as `.dart.txt`; current signup acceptance uses `direct_registration_test.dart`.
