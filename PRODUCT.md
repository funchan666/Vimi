# Vimi

An English Android dance community built with Flutter and Dart. Adults share K-pop, girl-group and boy-group covers, join choreography prompts, keep a private practice journal and talk after mutually following.

The user explicitly selected Flutter/Android and Supabase. These choices override the invoked majiabao skill's RN/iOS and local-only defaults. No iOS target, WebView business interface, StoreKit, fabricated users, automated followers or fake messages.

## Approved visual identity

On November 19, 2026 the user approved the neon social direction: midnight violet surfaces, orchid-pink/violet/cyan gradients, credible dance photography and prominent dancer/cover/posting interactions. Follow `DESIGN.md` and the accepted reference `docs/design-preview/vimi-neon-floor-v3-concept.png` for subsequent screens and refinements. Preserve this identity while completing the functional journeys and acceptance requirements below. Approval concerns the visual direction, not successful runtime or payment verification.

The welcome uses the publisher's group and duet covers, with Sign in under Join the crew and legal links accessible before account access. The duet preview and the rest of the app require sign-in. Registration asks for active agreement to the Terms of Use and Community Guidelines, with separate access to the Privacy Policy and Child Safety Standards.

## Journeys

- Floor: browse approved dance photos/videos, switch the short-video feed to covers from followed dancers, filter by style, discover dancers, join original eight-count challenges, publish with gallery/camera, comment, save, report and block.
- Studio: keep practice sessions with routine, style, tempo, eight counts and notes. Set a weekly minute goal and track it against saved notes on this device. Replay a personal video with speed, mirror and loop controls. Optional coin-unlocked practice packs provide concrete reusable drills and planning prompts.
- The free streaming video library includes all ten publisher-supplied clips, with Solo/Duets/Groups filters, account-scoped local saves, native rehearsal controls and reusable stable clip references in practice notes. All 55 supplied photos are available online in the profile image library with full preview and avatar-crop preview before an explicit profile save. Library bookmarks are local references, not offline video downloads.
- Inbox: real Supabase direct messages between mutually following adults. A rehearsal invitation combines the routine and a time or note in an editable chat draft for the user to send. New conversations and every send check the relationship on the server.
- Me: dance identity, own posts including review states, relationships, saved posts, practice history, wallet ledger and settings.

## Contracts

Email/password authentication and recovery use Supabase Auth. Sessions use encrypted device storage. Accounts are 18+; date of birth is checked during server provisioning, not advertised as identity verification. All uploads are private, posts/comments enter a moderator queue, reports hide reported content for the reporter, blocks take effect across queries and messaging. Account deletion removes owned Storage objects and Auth data. Limited financial and safety records may remain with direct profile links removed; transaction identifiers and restricted metadata are not described as fully anonymous.

Coins have seven planned Google Play consumable IDs. Local prices come exclusively from Play. The backend verifies the purchase token and the obfuscated account ID, grants an idempotent credit in a locked database transaction, and consumes the token after crediting. No client balance writes. Basic social actions are free. Refunded purchase handling and Play service credentials are required release configuration.

The publisher supplied 55 photos and ten videos and confirmed commercial App distribution, likeness and existing soundtrack rights on November 19, 2026. All are compressed and delivered from a separate public Supabase publisher-library bucket; the rights confirmation and source/runtime inventory are in `docs/media/`. This is publisher confirmation, not independent rights clearance. Library performances and images do not create registered dancers, posts or engagement. The library is for viewing/private rehearsal and does not grant members a licence to republish another person's music or performance. Authored challenges and original brand photographs remain editorial app content. Members must have permission to upload media and audio.

## Functional completeness and acceptance

The user's November 18 clarification requires a complete functional product, not a tab shell or a collection of display cards. Main destinations are entry points into working detail, creation, editing, result, relationship and settings flows. Tab count and screen count do not establish completeness.

Each core journey must cover meaningful input, validation, action, an actual result, persistence and reopening, cross-page refresh, loading/empty/error/cancel states and duplicate-submit handling where applicable. App flows and external configuration must be distinguished from actual runtime acceptance. Source implementation or a successful deployment must never be reported as a flow having run successfully.

The current journey-level acceptance record is in `docs/FUNCTIONAL_ACCEPTANCE.md`. It records existing source entry points and the unverified/configuration-dependent work without inventing successful interactions.

## Verification boundary

The November 19 continuation explicitly requests complete working journeys. This task authorizes analysis, relevant tests, Android debug compilation and emulator flow verification, in addition to source/configuration/resource review and necessary backend fixes. Keep actual device, simulated widget, database transaction and live-service evidence separate. Real Google Play purchases require the publisher's remaining credentials/products; no public release or store upload is authorized.

## Publisher media delivery update

On November 19, the publisher explicitly approved migrating all 55 images and ten videos to Supabase and removing their local package copies only after verification. Stable library IDs resolve to public URLs; version-1 asset references in existing practice notes, drafts and recovery copies remain resolvable without rewriting private journal data. Member uploads remain in the separate private bucket. The publisher subsequently requested deletion of original and optimized project backups; ProjectMaterials/Supplied has been removed.
