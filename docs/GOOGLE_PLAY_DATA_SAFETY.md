# Vimi Data safety worksheet

This is a source-based worksheet, not a submitted form or a blanket declaration. Reconcile it with the final AAB, service-provider terms/logging and the developer's support practices before submission. Account and cloud functionality use Supabase; offline guest practice is a separate device-only path. Follow the current [Google definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

| Candidate Console data type | Actual source/processing | Purpose / requiredness to assess |
| --- | --- | --- |
| Personal info → Name | Public display name | Account management / app functionality; required for account creation |
| Personal info → Email address | Supabase Auth; password recovery and support | Account management / functionality; required for registered community |
| Personal info → User IDs | Auth UUID, relationships, participant/author IDs; obfuscated purchase account ID if billing operates | Account management / functionality / fraud prevention |
| Personal info → Other info | Private date of birth and password-based authentication processing | Adult-access rule / security and compliance; required for signup |
| Messages → Other in-app messages | Supabase message body and participants | Messaging functionality; optional action |
| Photos and videos → Photos / Videos | Uploaded avatar/post media; selected video may contain audio | Social functionality; optional uploads |
| App activity → Other user-generated content | Bios, captions, comments and report reasons | Social functionality / safety and compliance; optional contributions |
| App activity → Other actions / app interactions | Likes, saves, follow/block/report activity and timestamps | Functionality / safety and compliance; optional member actions |
| Contacts / social graph | Follow relationships and identifiers, without reading the device address book | Check Google's social-graph definition against the actual relationship fields; absence of a contacts permission does not establish absence of collected graph data |
| App activity → In-app search history | Search terms/filters are sent to the database endpoint; observed provider logs contain request URLs with search filters | Collected off-device for functionality and request/security logs; do not declare uncollected or ephemeral without reconciling actual retention |
| Financial info → Purchase history | Product/order IDs, purchase tokens, balance, unlocks, ledger and refund state when billing runs | Fulfillment / security and compliance; optional purchases. Recheck the precise submitted billing-enabled build |
| Location → Approximate location | Observed provider log fields contain IP-inferred city and country | Disclose collection for infrastructure operation/security, despite no Android location permission |
| Device or other IDs / diagnostics | Observed provider logs include TLS/client fingerprint, user agent and authentication/session metadata | Declare the provider identifier and diagnostic processing under the applicable categories; no advertising identifier is read by the app |

Local-only practice notes, drafts, rehearsal files and drill progress are not automatically cloud-synced; distinguish them from a deliberately published photo/video. No standalone audio upload, microphone SDK recording, address-book access, advertising identifier SDK, health platform integration, advertising SDK or third-party behavioral analytics SDK is implemented in this version. This does not erase the cloud/account/social data above.

## Collection and sharing

- Answer collection from actual off-device processing, including providers and request logs, rather than only Android permissions.
- Assess optional/required per Google's form definitions, taking account of the genuine guest practice mode and which community actions require an account. Required at signup and optional for an app-wide guest are different questions; do not copy a rigid answer without checking the form wording.
- Review the service-provider and user-initiated sharing exceptions. Supabase processing and member-requested social visibility should not be blindly labelled advertising sharing, or blindly described as no sharing without verifying the relevant exceptions and provider practices.
- Do not mark payment-card collection merely because Google Play handles a purchase; Vimi receives order/receipt information, not full card numbers. Do not omit purchase history once real billing is enabled.
- No claim of independent security certification, E2E messaging encryption or fully anonymous retained audit records is made.

## Security, deletion and form alignment

The app uses HTTPS/secure Realtime, scoped authenticated data access, encrypted auth/pending-purchase storage and a private upload bucket. Device journals/drafts are not all encrypted. Account deletion removes linked social data and owned media; limited transaction/security records and provider logs/backups may remain for their stated purposes. Public policy and deletion URLs must be deployed and checked before supplying them to the form. Use the final release's exact privacy URL, adult target audience, IARC answers and App access details consistently.

## Hosted log evidence

A read-only aggregate over the current provider log window found 2,848 edge requests with city/country and TLS fingerprint fields, and 17 request URLs with search filters. Only counts and field names were retrieved; no IP, fingerprint, search text or personal log value was copied. This establishes that “no location permission” and “no stored search table” do not support a no-collection declaration. See `verification/2026-11-19/play-provider-log-fields.json`.
