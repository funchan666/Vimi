# Vimi functional acceptance

The user requires comprehensive functionality and working journeys, rather than only tab pages. This record is the acceptance contract for the current Flutter Android dance community. It adds no unrequested platform migration or fabricated social activity.

## Journey evidence

| Journey | Current result | Remaining boundary |
| --- | --- | --- |
| Account | Native immediate signup without verification; wrong-password denial; correct-password sign-in; separate operator login; genuine deletion. Original verification-email/PKCE callback also passed before the requested configuration change. | Production recovery SMTP and physical devices require publisher setup/acceptance. |
| Publishing | Genuine Android image picker → private Storage bytes → pending owner archive → approval → visible post → edit back to pending → deletion cleanup. Draft restoration/discard is covered by widget/storage tests. | Camera hardware capture and exhaustive interruption/permission cases have not been device-certified. |
| Community | Actual post details, like/save, comment submission/approval, caption edits and profile persistence verified against hosted data. | Large-history reads use current batch limits; no unlimited-history claim. |
| Dance relationships | Two real temporary accounts explicitly followed each other; native profiles and actual block/unblock results were checked. No automatic follows or restoration on unblock. | Broader device/account-scale acceptance remains separate. |
| Messaging | Real outgoing message, second-account reply, Realtime delivery and read receipt on Android; RLS/relationship denial verified in hosted rollback tests. | No end-to-end encryption or calling is claimed. |
| Dance practice | Native save/reopen/edit plus storage/widget create/delete/corruption recovery and account isolation. Video-specific results are in VERIFICATION.md. | Private notes/videos remain local to each account/device. |
| Coins and practice packs | Hosted rollback tests pass for no client credit, duplicate credit, unlock-once, refund debt and debt settlement. Wallet truthfully disables checkout. | Store products, Google credential, signing, testing-track installation and actual Play transactions are still required. |
| Safety/operations | Real native moderation/approval, report hiding/status/resolution, block messaging denial and separate fixed operator access. Support email is configured. | Publisher identity, jurisdiction, public policies and operational response staffing remain publisher responsibilities. |

## Acceptance rules

- Verify user actions through their resulting data and visible state, including reopening and returning from another page. A route opening is not sufficient.
- Cover loading, no content, validation errors, permission denial/cancellation, network failure/retry and repeated submission where the journey uses them.
- Financial and account-deletion paths require their actual platform/server results. Do not simulate payment success or label an unconfigured service usable.
- Preserve genuinely empty community states until actual members publish approved content. Do not create fake users, replies, follows or engagement to fill screens.
- Record build evidence, device/runtime evidence, live-service evidence and store/payment evidence separately. Mark each unperformed stage as unverified.

## Current acceptance status

The app has progressed beyond source-only delivery: active-source analyzer, eleven focused widget/storage tests, Android debug builds and meaningful native/live-service paths have actual evidence. `VERIFICATION.md` and `verification/2026-11-19/*-results.json` separate proven journeys from remaining platform/publisher-dependent checks.

No signed store release or real Play transaction is claimed. Earlier generated design concepts use illustrative names and are not runtime evidence; native verification screenshots are labelled separately. Temporary QA users/content are removed after verification.
