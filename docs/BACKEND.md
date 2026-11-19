# Vimi backend

Created with the user-selected Primary account and organization `vlktosuaxlyxcufhhfzx`. New project `Vimi`, ref `hgxbfgcdfsalavdfyvjr`, region `us-east-1`, project state `ACTIVE_HEALTHY`. Creation quote: $0/month; actual future usage remains subject to Supabase quotas and plan terms. No other project's data or configuration was changed.

[Open Vimi dashboard](https://supabase.com/dashboard/project/hgxbfgcdfsalavdfyvjr).

## Deployed

Six local migrations have been applied. All 15 public tables have RLS; private account dates, receipt hashes, API limits and moderation audits have RLS with no client policies intentionally. The `dance-media` bucket is private with a 50 MiB limit and constrained MIME types. Upload keys must be `<auth.uid()>/posts/<file>` or `<auth.uid()>/avatar/<file>`. Other members can access only approved, visible post media and visible avatars through authenticated requests; generated media URLs expire in 5 minutes. A signed URL already issued remains usable until expiry.

All exposed client RPCs are security invokers. Privileged implementations live in the non-exposed private schema, have fixed search paths, use the caller's authenticated user and enforce ownership/relationships. Service-only financial/admin operations have no client EXECUTE grant. Wallet credit/unlock/reversal operations lock the wallet and use unique ledger references. Block/follow/message mutations serialize a pair to keep their relationship checks together.

Four Edge Functions are ACTIVE:

- `verify-play-purchase`: authenticated user, product whitelist, request limit, Google verification/account binding, idempotent credit, server consumption. Requires the publisher's Play service credential to operate.
- `delete-account`: authenticated, recent password sign-in, explicit matching user ID; restricts the account, revokes sessions, removes owned media, deletes Auth data and cascades social data. Financial records lose their account link. A partial deletion is surfaced as a resumable deletion state.
- `moderate-content`: requires server-managed `app_metadata.vimi_role = moderator`; queues posts/comments/reports, supplies short-lived review media URLs, approves/rejects content, resolves reports and suspends/reactivates users.
- `reconcile-play`: same moderator requirement; reads Google's voided purchases and reverses known credited tokens, once each. Follow `next_page_token` until null. No automatic schedule was configured.

Gateway JWT verification is off because **each function independently validates the Bearer token with Supabase Auth before processing anything**. The moderator role is read from server-managed app metadata, never user-editable metadata. Function bodies never return or log purchase tokens or private keys. `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are supplied by the Supabase Edge environment, not the mobile app.

## Current Auth configuration

Primary's hosted Site URL and allowed Redirect URL are both `com.vimistudio.vimi://auth-callback/`. The values were saved through the authenticated dashboard and verified by a genuine signup email and Android PKCE callback.

The user subsequently requested signup without email verification. Hosted **Confirm email is now disabled**, matching `supabase/config.toml`; ordinary new accounts receive a real session immediately. Existing accounts still require their actual password. The app retains adult date-of-birth and policy-consent validation. No client or arbitrary email gains moderator privileges.

Password recovery continues to use the native callback. The built-in Supabase mail sender delivered to the provided organization-owner test email; production SMTP and delivery limits still require publisher configuration for general delivery.

## Moderation operation

The user requested an independent fixed operator account. `reviewer@vimi.invalid` is an internal, non-delivery login address; its server-managed app metadata grants `vimi_role: moderator`. Its generated password is stored only in ignored, mode-0600 `config/reviewer-access.json`. It is not a client constant or a build configuration value for the distributable application. Keep that file private and use Settings → Change password to rotate the credential.

`funchan7777777@gmail.com` is the support contact. Its temporary email-test account has no moderator role. Temporary QA actors are separate fixtures and are removed after acceptance.

Use the signed-in moderator's access token to call `moderate-content`. Examples of JSON bodies:

```json
{"action":"queue"}
```

```json
{"kind":"post","id":"ACTUAL_POST_UUID","status":"approved"}
```

Supported kinds/statuses: post/comment → approved/rejected, report → resolved, user → suspended/active. Read and inspect the actual media before approving. Approval does not happen automatically. Operators must publish an accessible support contact and run this queue with a real response process.

Migration filenames were created by the inspected Supabase CLI 3.2.0. Hosted transaction/rollback checks cover social/RLS/idempotency and wallet/unlock/refund invariants. Native Android verification and concrete limitations are recorded in `VERIFICATION.md`; SQL financial invariants are not Google Play transaction evidence.

Latest hosted advisors: no health findings; four intentional INFO notices for private tables with default-deny RLS; unused-index INFO on the small new dataset; leaked-password protection remains disabled (WARN). See the [password-security setting](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) and `verification/2026-11-19/hosted-advisors.json`.
