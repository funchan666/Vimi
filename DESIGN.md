# Vimi design system · neon social

Approved visual baseline: on November 19, 2026 the user accepted this neon direction and its social-home concept with “这个不错，就按这个方向来。” Continue all Vimi screens, secondary flows, controls and original assets within this identity. The approved reference is `docs/design-preview/vimi-neon-floor-v3-concept.png`; its illustrative people/content remain design examples, and approval of the direction is not runtime or end-to-end acceptance.

On November 19 the user explicitly rejected monochrome/gray photography and requested a cool neon-gradient effect with a stronger social feel. This pinned brief replaces the earlier cream/comic and monochrome directions. Natural anatomy and photographic credibility still matter; neither a black-white editorial treatment nor comic illustration is the target.

The Floor leads with actual publisher dance covers and portraits. Search, publishing, style filters and challenges connect this media to the member community. Studio organizes practice and reference clips. Inbox handles real conversations, and Me groups the member’s own covers, saved items and profile actions.

| Role | Value |
| --- | --- |
| midnight ground | #0C0716 |
| elevated panel | #1B122B |
| main text | #F7F2FF |
| secondary text | #BBB0CD |
| quiet selected surface | #322143 |
| input boundary | #806899 |
| action pink | #F58BDD |
| violet | #BBA4FF |
| cyan | #86E7F4 |
| label on bright gradient | #170C24 |
| error text | #FFA3B5 |

Original `neon-spectrum.webp` supplies a luminous orchid-pink → violet → cyan field. The app clips this real raster for primary buttons and active filters, uses it for the active-navigation icon tile and softly composites it into page/panel backgrounds. Primary labels are dark violet for contrast. Secondary controls use quiet violet surfaces and compact original glyphs; body copy stays light and readable. Native focus, keyboard, text selection, system Back and platform payment/permission flows remain functional framework/platform behavior.

DM Sans remains the bundled face, with 30 display, 25 headline, 20 subheading, 14/21 body and 14/18.2 controls. Signed-in sections use 17-point labels and written detail routes use a compact 16-point navigation title. Welcome uses a 44 headline, reduced to 38 on narrow phones. Panel/control radii are 16; the challenge photo is 20 and welcome performance frames 26. Spacing follows 4/8/12/16/20/24/32. Icon targets retain at least 48 logical pixels and primary actions at least 52. All artwork remains original project raster imagery; no code-drawn replacement icons, gradient artwork, system icons, emoji icons or template icon packs were introduced.

Compact navigation keeps Floor, Studio, Inbox and Me as icon-only destinations in a floating panel; expanded layouts use an icon-only 84-wide rail at the existing 760 breakpoint. The November 19 refinement removes the visible navigation captions in both layouts. The selected icon uses the original neon raster tile with dark ink; every destination retains its English accessible name, long-press tooltip, selected semantics and a 52×48 target. Welcome preserves scrollability and switches to a two-column composition on expanded widths. Header/controls and native text can resize; the challenge overlay grows with its actual text instead of locking it to a fixed-height box.

The four signed-in destinations omit the shared title bar. Floor opens on a large duet cover with a photo wall and challenge tile beside it. The clip and portrait strips lead directly to playback and full-image viewing. Member covers retain style filters, profile links, comments, saves and reporting. Actual member data drives names, avatars and posts. A publisher clip opens as a practice reference without a member identity.

Challenges use publisher clips as playback references for the routine style. Welcome uses publisher duet and group performances. Contributing a challenge take opens the normal composer with the challenge attached. Profile and outgoing-message panels use a quiet tinted gradient; wallet coins and discovery use cyan highlights. Forms, safety sheets and feedback share the dark system rather than reverting to light defaults.

Current original PNGs/prompts and measured mappings are in `assets/brand/`; the previous exact UI/source/assets snapshot is `docs/design-history/2026-11-19-monochrome-v2/`. Active rasters are in `assets/ui/`. No history, prompt, original PNG or visual concept enters the Flutter asset bundle.

The publisher’s 55 photos and ten videos are visible through Discover, the profile image selector, the short-video feed and Studio. Photo picks leads to the full community gallery. Media tiles use actual optimized photography and first-frame covers, a lazy responsive grid, DM Sans labels and the existing violet/pink/cyan controls. No fake member rows or social statistics are attached to these supplied assets. Photo detail provides full-image zoom plus the same centered crop used by the profile. Clip detail reuses the existing native player and practice controls. Its note points to a stable cloud-library ID without copying video bytes. All source and derivative mappings are in `docs/media/SUPPLIED_MEDIA.md`.

The initial brand-design pass used static source/resource inspection and generated-art review. `docs/design-preview/vimi-neon-floor-v3-concept.png` remains an image-generated concept with illustrative member content. Later native verification is recorded separately in `docs/VERIFICATION.md`; the concept itself is not runtime evidence.

## Compact action refinement · November 19

The user asked for fewer text buttons and no Tabbar captions. Primary results such as saving a profile/practice, submitting a post, purchasing and destructive confirmations retain explicit labels. Frequent utility actions use the original raster glyphs, with quiet violet or selected neon skins. Settings, help, wallet, library and journal entries are complete clickable rows with a destination name, content context and the original next glyph. Follower counts read as profile statistics instead of pink action labels.

Rehearsal uses two compact rows: back/play/forward with an actionable time value, then mirror, loop, speed, sound and full-screen controls. Speed opens a four-value sheet; tapping the timestamp opens precise second entry. The full frame fits within a viewport-relative height without cropping, and full-screen continues to share the same native controller. Publishing has photo/video import and a camera source sheet; editing has image-library/gallery/camera icons. Report/block tools remain available with accessible names and explicit safety sheets.

Garden / GPT Image 2 Host-Native generated one original eight-glyph transparent atlas: `assets/ui/utility-controls-v4.webp` (245,234 bytes, lossless WebP). Its source is `assets/brand/sources/controls-v4/utility-controls.png`, prompt `garden-gpt-image-2/prompt/vimi-controls-v4-20261119.md`, measured rectangles in `assets/brand/asset-inventory-v4.json`. Only the runtime raster enters the bundle. No icon pack or code-drawn replacement artwork was used.

Skill routing: UI Design Reference, UI Taste (Distill/Craft), Impeccable (Distill/Craft Floor), and Garden / GPT Image 2 with the native image-generation workflow. Marketing frontend Taste, Claude HTML artifacts and browser-only Garden modules do not fit this Flutter refinement; no web conversion or new concept approval round was introduced.

## Cloud library delivery

Publisher photographs, thumbnails, covers and full videos load from the separate public Supabase library. The selected neon identity and original local UI rasters remain unchanged. Image loading reserves its current layout; failures expose an original refresh glyph with an accessible Retry image label. Profile save downloads a bounded, hash-verified image before the existing private account upload. Video initialization has a connection/retry state. Library copy states that clips stream online and saved items are bookmarks. Old asset note references resolve through the local metadata catalogue to current cloud URLs; they are never treated as missing personal files.

## Welcome redesign · November 20

The entry uses two overlapping, lightly angled performances from the cloud library: `street-style-group` and `holiday-duet`. Each frame leaves enough space for its full rotated outline. The duet leads to sign-in and then to its streaming detail with the existing practice-note journey.

“Meet your dance crew.” introduces the community. The gradient Join the crew button opens registration, with Sign in directly beneath it and Terms of Use, Privacy Policy and Child safety in the footer. The phone composition scrolls for small screens or larger type, and expanded screens place the performances and entry content side by side. Frames reserve their space while images load and keep their retry controls.

Sign-in opens on a dusk duet photo, while registration uses a rehearsal group photo. Each uses the matching cloud-library cover and a neon edge. On phones the photo sits above the form and scrolls away while Back stays accessible. Expanded layouts pair the photo and form side by side. Form fields share a surface with dividers, and registration separates the profile details from the credentials. Password recovery sits beneath the sign-in fields. The registration agreement is unchecked by default, and the policy links can be read independently. The signed-in shell uses icon-only navigation with English accessibility labels.

The supplied 512×512 Logo is used directly on the Flutter launch screen and in the Play Store and policy-site assets. Android launcher resources use scaled copies of the same image. The native and Flutter startup screens use a dark indigo background (`#100B24`), a centered mark and a slim cyan loading indicator. The Flutter indicator runs while initialization is in progress and becomes static when reduced motion is requested.

UI Design Reference, UI Taste, Impeccable and Claude Design guided the hierarchy and composition. Garden image generation was evaluated; the existing project rasters and publisher-supplied photography satisfy this revision without new generated people. The retired `neon-welcome.webp` is removed from the runtime assets; source/provenance remains in the brand inventory. Android screenshots and focused route verification are recorded separately from the design rationale.

## Signed-in community · November 20

Floor opens on a vertical video feed of approved member covers and publisher practice references. An inset, rounded video frame uses a compact credit and action strip below the picture. The current video loops muted, and its sound toggle, tap-to-pause and progress indicator stay accessible. Discover opens the photo and video mosaic, member covers and challenges. Studio puts rehearsal clips beside saved clips, the journal and the last seven days of recorded practice.

Me opens on a larger tappable profile avatar, identity and relationship counts. The labelled Coin wallet tile displays the account balance and opens the coin packs. Below it are shortcuts to saved member covers, saved publisher clips and the local practice history. My covers displays the member’s own posts with their review state and editing and publishing actions. Publisher photo picks live in Discover and the avatar selector.

Inbox places search and compose beside each other, above the All and Unread filters. Each conversation shows the member’s avatar, last message, timestamp and any unread count. Real mutuals can start a chat from the avatar strip. An empty inbox uses a small messaging state and, when available, actual dancer profiles to discover. Chat details group messages by day and keep the composer below the scrolling history.

Member avatars use the saved profile photo first. Accounts without one display an account-specific selection from eight publisher library thumbnails. These images are display defaults, and users can tap their own avatar to select and save a photo. An unavailable image shows the member’s initials.

The Floor toolbar switches between All covers and Following. Following filters the existing paginated, approved member results using the signed-in dancer’s follow relationships. An empty result offers discovery or a way to browse older covers. Studio’s weekly practice goal shows actual journal minutes for the local Monday–Sunday week. The chat toolbar’s practice invitation adds an editable routine and plan to the composer after verifying the mutual follow.

The screens use the supplied cloud media and existing original glyphs. UI Design Reference, UI Taste, Impeccable and Claude Design informed the compact hierarchy. Android execution is documented in the dated community verification record.
