# Native acceptance

Run the focused local suite with `flutter test test`. It needs no hosted credentials. Native targets use the real Android plugins and real Vimi Supabase services; assertions check resulting data as well as UI state.

Native suites run individually with the extended driver:

```sh
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/direct_registration_test.dart \
  -d emulator-5554 --dart-define-from-file=config/qa-runtime.json
```

The ignored QA configuration is intentionally removed after acceptance. Prepare fresh disposable fixtures before another run. It contains Vimi's publishable client configuration, the labelled QA emails/passwords/IDs, a QA run ID, a next test password, and the separate operator login. Never put a service key into the app. Destructive suites reject emails outside their expected `vimi-qa-…@example.invalid` patterns.

`social_flows_test.dart` starts with fresh A/B fixtures, signs in as B and opens the challenge publisher before testing native picker/upload and two-account Realtime messaging. `social_detail_test.dart` is the continuation target for an existing labelled A/B fixture post and deletes both actors when complete. The A fixture needs a server-assigned moderator role. Create no permanent fake community activity.

`video_practice_test.dart` mounts Studio in a local test harness and uses the real Android picker with `test/fixtures/rehearsal-sample.mp4`. The host selects the labelled imported fixture, responds to the explicit display-resize/restore markers, and restores the emulator's original settings. The MP4 contains a still photo for testing the decoder.

`recovery_test.dart` uses a dedicated temporary account with access to its real mailbox. The host opens only that run's genuine project recovery link and returns its native callback. It does not bypass email ownership or fabricate recovery success.

Passwords/tokens must not enter logs or response data. Current successful evidence and cleanup counts are in `docs/verification/2026-11-19/acceptance-summary.json`. The superseded confirmation-required test is preserved as a plaintext historical snapshot because current signup is explicitly confirmation-free.

## History and playback continuity regression

The current hardening pass adds `history_flows_test.dart` and `player_continuity_test.dart`. The former covers search resets, relationships, archive/comment/chat/report/ledger history, unsent drafts, Realtime arrivals and sectioned reviewer queues; the latter covers Inbox pages and a genuine native decoder with full-screen controller/settings continuity.

On a deliberately isolated QA run, `tool/prepare_history_qa.py` creates two labelled Auth actors and stores their credentials in ignored mode-0600 `config/qa-history.json`. `tool/seed_history_qa.py` uploads owned fixtures and prepares `config/qa-history-seed.sql`; review/apply that SQL only to this Vimi QA target through the connected project tool. Use the prepared JSON as the Dart define file. Set `VIMI_QA_OUTPUT` to a new evidence directory when driving the suites. Python helpers require certifi for certificate validation; they never disable TLS verification.

`tool/check_history_backend.py` verifies queue pagination and role/input denial. After acceptance, `tool/cleanup_history_qa.py` deletes only the two labelled actors via the authenticated deletion function. The remaining directory-only fixture users and zero-value QA ledger rows must also be removed using their exact run-specific email/reference prefixes. Verify hosted counts, inspect a main-entrypoint APK against the actual private values with `tool/inspect_preview.py`, then remove both private QA configuration files. Keep the fixed reviewer account. Historical results in docs are evidence, not seeded production members.
