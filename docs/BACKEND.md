# Vimi backend

The current Android client uses free practice plans. The payment functions and database history documented here describe the earlier checkout implementation.

Created with the user-selected Primary account and organization `vlktosuaxlyxcufhhfzx`. New project `Vimi`, ref `hgxbfgcdfsalavdfyvjr`, region `us-east-1`, project state `ACTIVE_HEALTHY`. Creation quote: $0/month; actual future usage remains subject to Supabase quotas and plan terms. No other project's data or configuration was changed.

[Open Vimi dashboard](https://supabase.com/dashboard/project/hgxbfgcdfsalavdfyvjr).

## Deployed

Ten local migrations have been applied. All 15 public tables have RLS; private account dates, receipt hashes, API limits and moderation audits have RLS with no client policies intentionally. The `dance-media` bucket is private with a 50 MiB limit and constrained MIME types. Upload keys must be `<auth.uid()>/posts/<file>` or `<auth.uid()>/avatar/<file>`. Active members can access only their own media, approved visible post media and visible avatars through authenticated requests; generated media URLs expire in 5 minutes. Suspended/deleting accounts cannot obtain new owner access through Storage RLS. A signed URL already issued remains usable until expiry.

All exposed client RPCs are security invokers. Privileged implementations live in the non-exposed private schema, have fixed search paths, use the caller's authenticated user and enforce ownership/relationships. Service-only financial/admin operations have no client EXECUTE grant. Wallet credit/unlock/reversal operations lock the wallet and use unique ledger references. Block/follow/message mutations serialize a pair to keep their relationship checks together.

Four Edge Functions are ACTIVE:

- `verify-play-purchase`: authenticated user, product whitelist, request limit, Google verification/account binding, idempotent credit, server consumption. Requires the publisher's Play service credential to operate.
- `delete-account`: authenticated, recent password sign-in, explicit matching user ID; restricts the account, revokes sessions, removes owned media, deletes Auth data and cascades social data. Financial records lose their account link. A partial deletion is surfaced as a resumable deletion state.
- `moderate-content` version 4: requires server-managed `app_metadata.vimi_role = moderator` and an active account; queues posts/comments/reports with stable oldest-first pages and a child-safety filter, supplies short-lived review media URLs, approves/rejects or permanently removes content/media, clears violating profile material, resolves reports and suspends/reactivates users.
- `reconcile-play`: same moderator requirement; reads Google's voided purchases and reverses known credited tokens, once each. Follow `next_page_token` until null. No automatic schedule was configured.

Gateway JWT verification is off because **each function independently validates the Bearer token with Supabase Auth before processing anything**. The moderator role is read from server-managed app metadata, never user-editable metadata. Function bodies never return or log purchase tokens or private keys. `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are supplied by the Supabase Edge environment, not the mobile app.

## Current Auth configuration

Primary's hosted Site URL and allowed Redirect URL are both `com.vimistudio.vimi://auth-callback/`. The values were saved through the authenticated dashboard and verified by a genuine signup email and Android PKCE callback.

The Android application ID is `com.vimistudio.covercrew`. The Auth callback uses the separately configured URI above. To verify email recovery on a device with both preview generations installed, open the link with the new app.

The user subsequently requested signup without email verification. Hosted **Confirm email is now disabled**, matching `supabase/config.toml`; ordinary new accounts receive a real session immediately. Existing accounts still require their actual password. The app retains adult date-of-birth and policy-consent validation. No client or arbitrary email gains moderator privileges.

Password recovery continues to use the native callback. The built-in Supabase mail sender delivered to the provided organization-owner test email; production SMTP and delivery limits still require publisher configuration for general delivery.

## Moderation operation

The user requested an independent fixed operator account. `reviewer@vimi.invalid` is an internal, non-delivery login address; its server-managed app metadata grants `vimi_role: moderator`. Its generated password is stored only in ignored, mode-0600 `config/reviewer-access.json`. It is not a client constant or a build configuration value for the distributable application. Keep that file private and use Settings → Change password to rotate the credential.

`funchan7777777@gmail.com` is the user-confirmed support and child-safety contact. Its temporary email-test account was removed and is not a moderator. Temporary QA actors are separate fixtures and were removed after acceptance. The ordinary reusable Play App access account is separate again: private `config/play-review-access.json`, no moderator role or special behavior. See `GOOGLE_PLAY_APP_ACCESS.md`.

Use the signed-in moderator's access token to call `moderate-content`. Examples of JSON bodies:

```json
{"action":"queue"}
```

```json
{"kind":"post","id":"ACTUAL_POST_UUID","status":"approved"}
```

Supported kinds/statuses: post/comment → approved/rejected/removed, message → removed, report → resolved, user → suspended/active/removed. For user removal, only the violating public profile is cleared; suspension and account deletion are separate actions. Post/profile removal deletes the associated Storage file before the atomic record/audit mutation. Read and inspect actual media before approving. Approval does not happen automatically. Operators must publish an accessible support contact and run this queue with a real response process. See `CHILD_SAFETY_OPERATIONS.md`.

The active-moderator lookup uses a service-only invoker RPC over a narrow private definer helper with a fixed search path. It reads server-managed Auth app metadata; ordinary clients have no EXECUTE grant, and service_role was not granted general Auth-table access. Permanent removal and its idempotent audit are service-only operations.

Migration filenames were created by the inspected Supabase CLI 3.2.0. Hosted transaction/rollback checks cover social/RLS/idempotency and wallet/unlock/refund invariants. Native Android verification and concrete limitations are recorded in `VERIFICATION.md`; SQL financial invariants are not Google Play transaction evidence.

Latest hosted advisors: no health findings; four intentional INFO notices for private tables with default-deny RLS; unused-index INFO on the small new dataset; leaked-password protection remains disabled (WARN). See the [password-security setting](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) and `verification/2026-11-19/hosted-advisors-play.json`. No plan upgrade was made.

## Stable history pages

Migration `20261119055131_vimi_cursor_history.sql` adds RLS-preserving `get_feed_page`, `get_thread_page` and `get_inbox_page`. Each uses `(created_at, id)` ordering and returns one lookahead row: 21/51/26 respectively for 20/50/25 visible rows. Forward the **last visible** timestamp and UUID as `p_before_created` and `p_before_id`. Thread history remains readable after unfollowing; sending still requires mutual follows, and blocks/reports remain enforced by RLS. Composite indexes cover the equality filters and cursor order.

`moderate-content` version 4 accepts `{"action":"queue","section":"comments"}` (or posts/reports) and returns `items`, up to 26 rows for 25 visible entries. Reports also accept `"child_safety_only": true` to include Child safety and Underage user reasons. For another page supply `after_created` as an exact UTC ISO timestamp ending in Z, retaining its fractional seconds, and `after_id` from the last visible row. Invalid sections/cursors are rejected. The legacy unsectioned response remains compatible with previous clients.

Hosted rollback contracts, actual reviewer API pagination/role checks, and the two current native history/continuity suites are recorded in `verification/2026-11-19/`. Temporary fixture actors/content/media and zero-value ledger entries were removed after acceptance.

## Direct calls

Migration `20261123072821_vimi_direct_calls.sql` adds one-to-one voice and video calls between eligible mutual follows. Realtime delivers incoming call state while the app is open. The server binds signaling to the participants' Auth sessions and ends active calls when a block, unfollow, user report or account restriction makes the pair ineligible. Ringing expires after 45 seconds. An accepted call expires if either side stops sending heartbeats. A scheduled job removes expired signaling and clears ended call metadata after about a day.

Flutter uses WebRTC with STUN for direct connections. The optional `VIMI_CALL_ICE_FUNCTION` build setting names an authenticated Supabase Edge Function that returns an object with `iceServers` containing temporary TURN credentials. Persistent TURN credentials belong in server secrets. The preview configuration has no TURN issuer, and background push calling is unconfigured.

## Publisher clip engagement

The ten publisher clip IDs match `assets/data/media_library.json`. Likes and approved comment counts are calculated per clip. Library comments share the existing comment review queue, reporting, block visibility, and author deletion. Public comment lists show approved comments, with pending and rejected comments visible to their author.

Studio’s editorial bylines link to individual editorial profiles for the supplied clips. A verified creator link takes precedence and opens that member’s profile. The publisher may set `private.library_clips.author_profile_id` to a consenting creator’s existing profile UUID after verifying the credit. The catalog starts with no creator associations or seeded interactions.
