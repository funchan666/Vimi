# Vimi Google Play readiness · 19 November 2026

**Not a submission clearance or a promise of approval.** This audit covers this Vimi checkout, its recorded ARM64 preview and its Supabase project. It does not inspect the developer's Play Console, account history, other apps or a future upload-signed AAB. Current publishing blockers are recorded by `tool/play_release_check.py`.

## Changes completed in this pass

- The signed-out welcome has terms, privacy and child-safety links. During registration, users actively accept the Terms of Use and Community Guidelines before account creation. The Privacy Policy and Child Safety Standards are independently readable. Returning members sign in with their credentials. Date of birth is entered without a preset or a qualifying-age hint. See [Google Play's neutral age screening guidance](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en#neutral-age-screen).

- Dedicated Child safety report reason and reviewer filter, alongside underage-user reports. Publicly readable in-app child-safety standards and the designated contact `funchan7777777@gmail.com` are available without signing in.
- Moderators can permanently remove a post and its Storage media, remove comments/messages and clear a profile's name, bio and avatar. Reported avatars have genuine review URLs. Removal and its audit record use a service-only transaction; ordinary members cannot call it. A suspended moderator no longer passes the access check. Existing report completion and suspension remain separate explicit actions.
- Account-unavailable screens retain deletion and support routes. Account deletion also scrubs account UUIDs from pack-ledger references; restricted transaction/safety records are not inaccurately described as fully anonymous.
- Storage read rules now require an active account even for an object's owner. Previously issued short-lived signed links retain their original expiry; suspended/deleting owners cannot use RLS to obtain new access. A hosted rollback test verifies the active/suspended distinction.
- Privacy, terms, guidelines, child-safety and deletion text now describe the actual cloud/device boundary, messages, media, provider processing, IP/request logs and permitted record retention. Upload visibility is explained in the profile and publisher.
- Standard HTML policies are generated from those same bundled text files under `policy-site/dist`. The deletion page opens an email request without requiring app reinstallation. Publication and an unauthenticated public HTTP check are still required before entering a URL into Play Console.
- `validatePlayRelease` blocks release variants with missing policy URLs, contact addresses, backend configuration, upload signing, server-only client secrets. Profile/debug previews remain available. This gate validates configuration, not Google approval or legal compliance.

## Evidence and boundaries

| Area | Observed evidence | What remains |
| --- | --- | --- |
| Target API | Current 36,909,069-byte preview targets API 36; source pins 36 | Check the final submitted AAB again |
| Permissions | Current source declares network, camera and audio permissions for uploads and calls. Gallery imports use the system picker. | Reinspect the merged release manifest after SDK changes. |
| App pricing | Current source removes Google Play Billing and the wallet. The three practice plans are free. | Confirm the final AAB manifest and Play Console listing. |
| 16 KB pages | Current ARM64 preview ELF load segments and APK zip alignment pass static 16 KB checks | A final AAB and actual 16 KB device/runtime run are separate checks |
| Child safety / moderation | SQL rollback and actual harmless-fixture API removal/role checks are recorded under verification/2026-11-19 | A trained, available human operator and legally appropriate escalation/reporting procedure; code cannot replace this |
| Account deletion | Genuine deletion was previously verified; a suspended actor also completed real native deletion in this pass | Support must verify and fulfill emailed deletion requests without requiring reinstallation |
| Policy URLs | Source and standard HTML pages are complete | Public hosting without login/geofencing/download behavior, then match app and Console URLs |
| Store access | An ordinary reusable account is provisioned in private config/play-review-access.json; provide it in App access | Never provide the content-moderator password as the ordinary member login |
| Supplied reference media | All 55 photos/ten complete videos are compressed, bundled and covered by native checks; publisher confirmed commercial/likeness/audio rights | Keep underlying rights and required attribution records; confirmation is not independent legal clearance. See media/SUPPLIED_MEDIA.md |
| Data safety | Source-based mapping in GOOGLE_PLAY_DATA_SAFETY.md | Confirm against final SDKs, provider logs, support practices and direct-call infrastructure |
| Developer / store forms | No operator company or legal jurisdiction was invented; the publisher confirmed there is none to supply yet | Genuine developer identity/package registration, audience 18+, IARC, child-safety declaration and access instructions |

## Before submitting

1. Publish the policy pages as real public HTML and verify every URL without a browser login. Use the same privacy and child-safety text as the app. Confirm the publisher/contact details against the actual store identity.
2. Run `python3 tool/play_release_check.py --check-public-urls`. Resolve all reported blockers. This cannot verify Console declarations or guarantee that a page is reachable in every country.
3. Complete developer verification using genuine details, and register `com.vimistudio.vimi`. Use Social as the category only if it accurately describes the final product. Do not reclassify merely to avoid child-safety requirements.
4. Declare the target audience as adults 18+ and answer IARC honestly about member posts, photos/videos and 1:1 messages. An adult audience does not exempt social apps from child-safety standards. The current date-of-birth check is not identity verification.
5. App access must contain a maintained ordinary review account, English instructions and access to all restricted features. Normal review behavior must match the released product. Keep operator credentials separate; do not add reviewer/device/IP-based feature switching.
6. Complete Data safety from the submitted build and actual service processing. Do not select “no data collected” for this Supabase social app, and do not claim end-to-end encryption or an independent security certification.
7. Prepare an upload-signed AAB. Check Play's pre-launch report, final manifest, target API, 64-bit/page-size packaging and supported devices. Screenshots/descriptions must show actual working features and avoid unlicensed music, idol artwork, fake engagement or promises of professional/AI scoring.
8. Operate moderation after release. Check child-safety reports promptly, act on confirmed violations and retain only legally necessary evidence with restricted access. Do not email or circulate suspected CSAM. Follow CHILD_SAFETY_OPERATIONS.md and applicable law.

## Product and account-level risk

Vimi includes dance-specific eight-count prompts, rehearsal speed/mirror/loop controls, a local practice journal and reusable practice planning. These features need to remain substantial and functional; changing only a name, colors or theme across many otherwise equivalent apps can create repetitive-content risk. Do not conceal functionality, misstate data collection, purchase reviews, use fake engagement or attempt to bypass a developer-account enforcement action. Google considers the broader account and app catalog as well as this binary.

## Official policy sources checked

- [UGC moderation and reporting/blocking](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en)
- [Child Safety Standards, including adult-only social apps](https://support.google.com/googleplay/android-developer/answer/14747720?hl=en)
- [Account deletion, including a web request route](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- [Public HTML policy pages and App content preparation](https://support.google.com/googleplay/android-developer/answer/9859455?hl=En)
- [User data / privacy requirements](https://support.google.com/googleplay/android-developer/answer/18265346?hl=en)
- [Data safety definitions and provider-processing distinctions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [16 KB packaging and runtime verification](https://developer.android.com/guide/practices/page-sizes)
- [Maintained review login requirements](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en)
- [Enforcement and related accounts](https://support.google.com/googleplay/android-developer/answer/9899234?hl=en)
- [Intellectual property and evidence of content rights](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)

## Name screening

Google Play currently lists other apps using “Vimi”, including [Vimi by ACR Tech](https://play.google.com/store/apps/details?hl=en-US&id=ai.videophoto.generator) and [Vimi: AI Photo to Video](https://play.google.com/store/apps/details?hl=en-US&id=art.vimi.ai). This is a same-name finding, not an infringement finding or trademark clearance. Do not treat the name as exclusive or imply affiliation with those products. Confirm naming/rights and a distinctive, accurate store identity before submission; no package, product ID or approved branding was silently renamed in this audit.

Publisher media now streams from a separate public Supabase bucket. The local privacy text, matching HTML and Data safety worksheet disclose delivery requests and provider network logs. Member uploads remain private and follow their existing approval/access rules. The migration did not enable billing, publish policy URLs or create a store release.
