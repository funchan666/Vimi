# Native acceptance

Run the focused local suite with `flutter test test`. It needs no hosted credentials. Native targets use the real Android plugins and real Vimi Supabase services; assertions check resulting data as well as UI state.

Native suites run individually with the extended driver:

```sh
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/direct_registration_test.dart \
  -d emulator-5554 --dart-define-from-file=config/qa-runtime.json
```

The ignored QA configuration is intentionally removed after acceptance. Prepare fresh disposable fixtures before another run. It contains Vimi's publishable client configuration, the labelled QA emails/passwords/IDs, a QA run ID, a next test password, and the separate operator login. Never put a service key into the app. Destructive suites reject emails outside their expected `vimi-qa-…@example.invalid` patterns.

`social_flows_test.dart` starts with fresh A/B fixtures and performs guest challenge continuation, a genuine native picker/upload and two-account Realtime messaging before the remaining journeys. `social_detail_test.dart` is the continuation target for an existing labelled A/B fixture post, and deletes both actors when complete. The A fixture needs a server-assigned moderator role; ordinary signup never grants one. Create no permanent fake community activity.

`video_practice_test.dart` uses the real Android picker with the original project photo and `test/fixtures/rehearsal-sample.mp4`. The host selects the labelled imported fixture, responds to the explicit display-resize/restore markers, and restores the emulator's original settings. The MP4 is a still-photo decoder fixture, not choreography or an app asset.

`recovery_test.dart` uses a dedicated temporary account with access to its real mailbox. The host opens only that run's genuine project recovery link and returns its native callback. It does not bypass email ownership or fabricate recovery success.

Passwords/tokens must not enter logs or response data. Current successful evidence and cleanup counts are in `docs/verification/2026-11-19/acceptance-summary.json`. The superseded confirmation-required test is preserved as a plaintext historical snapshot because current signup is explicitly confirmation-free.
