# Vimi design system · neon social

Approved visual baseline: on November 19, 2026 the user accepted this neon direction and its social-home concept with “这个不错，就按这个方向来。” Continue all Vimi screens, secondary flows, controls and original assets within this identity. The approved reference is `docs/design-preview/vimi-neon-floor-v3-concept.png`; its illustrative people/content remain design examples, and approval of the direction is not runtime or end-to-end acceptance.

On November 19 the user explicitly rejected monochrome/gray photography and requested a cool neon-gradient effect with a stronger social feel. This pinned brief replaces the earlier cream/comic and monochrome directions. Natural anatomy and photographic credibility still matter; neither a black-white editorial treatment nor comic illustration is the target.

The Floor is primarily an Explore surface: discover actual dancers, browse covers, filter dance styles and enter a challenge. Posting is the visible primary action. Messages, editing, settings and wallet are Operate/Configure surfaces in the same visual system. Navigation is an entry into complete existing journeys, not the deliverable by itself.

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

DM Sans remains the bundled face, with 40 display, 32 headline, 24 subheading, 16/24 body and 14/18.2 controls. Welcome uses a 38 headline. Panel/control radii are 16; the challenge photo is 20 and welcome photo 22. Spacing follows 4/8/12/16/20/24/32. Icon targets retain at least 48 logical pixels and primary actions at least 52. All artwork remains original project raster imagery; no code-drawn replacement icons, gradient artwork, system icons, emoji icons or template icon packs were introduced.

Compact navigation keeps Floor, Studio, Inbox and Me as icon-only destinations in a floating panel; expanded layouts use an icon-only 112-wide rail at the existing 760 breakpoint. The November 19 refinement removes the visible navigation captions in both layouts. The selected icon uses the original neon raster tile with dark ink; every destination retains its English accessible name, long-press tooltip, selected semantics and a 60×52 target. Welcome preserves scrollability and switches to a two-column composition on expanded widths. Header/controls and native text can resize; the challenge overlay grows with its actual text instead of locking it to a fixed-height box.

Floor composition: wordmark plus gradient Post action; short community heading; compact photo challenge entry; real dancer strip with profile routes; cover stream with style filters. Actual member data drives avatars, names and posts. Loading, empty and error states remain meaningful and actionable. No fictional members, online dots, follower counts, likes or messages are inserted to fill the community.

Welcome and the authored challenge use separate original neon-lit dance photographs of fictional adults. They are editorial app imagery, not represented as real members or user uploads. Profile and outgoing-message panels use a quiet tinted gradient; wallet coins and discovery use cyan highlights. Forms, safety sheets and feedback share the dark system rather than reverting to light defaults.

Current original PNGs/prompts and measured mappings are in `assets/brand/`; the previous exact UI/source/assets snapshot is `docs/design-history/2026-11-19-monochrome-v2/`. Active rasters are in `assets/ui/`. No history, prompt, original PNG or visual concept enters the Flutter asset bundle.

The publisher's 55 photos and ten videos extend the approved visual system through the profile image picker and Studio video library. Media tiles use actual optimized photography/first-frame covers, a lazy responsive grid, DM Sans labels and the existing violet/pink/cyan controls. No fake member rows or social statistics are attached to these supplied assets. Photo detail provides full-image zoom plus the same centered crop used by the profile. Clip detail reuses the existing native player and practice controls; its note points to a stable cloud-library ID without copying video bytes. All source/derivative mappings are in `docs/media/SUPPLIED_MEDIA.md`.

The initial brand-design pass used static source/resource inspection and generated-art review. `docs/design-preview/vimi-neon-floor-v3-concept.png` remains an image-generated concept with illustrative member content. Later native verification is recorded separately in `docs/VERIFICATION.md`; the concept itself is not runtime evidence.

## Compact action refinement · November 19

The user asked for fewer text buttons and no Tabbar captions. Primary results such as saving a profile/practice, submitting a post, purchasing and destructive confirmations retain explicit labels. Frequent utility actions use the original raster glyphs, with quiet violet or selected neon skins. Settings, help, wallet, library and journal entries are complete clickable rows with a destination name, content context and the original next glyph. Follower counts read as profile statistics instead of pink action labels.

Rehearsal uses two compact rows: back/play/forward with an actionable time value, then mirror, loop, speed, sound and full-screen controls. Speed opens a four-value sheet; tapping the timestamp opens precise second entry. The full frame fits within a viewport-relative height without cropping, and full-screen continues to share the same native controller. Publishing has photo/video import and a camera source sheet; editing has image-library/gallery/camera icons. Report/block tools remain available with accessible names and explicit safety sheets.

Garden / GPT Image 2 Host-Native generated one original eight-glyph transparent atlas: `assets/ui/utility-controls-v4.webp` (245,234 bytes, lossless WebP). Its source is `assets/brand/sources/controls-v4/utility-controls.png`, prompt `garden-gpt-image-2/prompt/vimi-controls-v4-20261119.md`, measured rectangles in `assets/brand/asset-inventory-v4.json`. Only the runtime raster enters the bundle. No icon pack or code-drawn replacement artwork was used.

Skill routing: UI Design Reference, UI Taste (Distill/Craft), Impeccable (Distill/Craft Floor), and Garden / GPT Image 2 with the native image-generation workflow. Marketing frontend Taste, Claude HTML artifacts and browser-only Garden modules do not fit this Flutter refinement; no web conversion or new concept approval round was introduced.

## Cloud library delivery

Publisher photographs, thumbnails, covers and full videos load from the separate public Supabase library. The selected neon identity and original local UI rasters remain unchanged. Image loading reserves its current layout; failures expose an original refresh glyph with an accessible Retry image label. Profile save downloads a bounded, hash-verified image before the existing private account upload. Video initialization has a connection/retry state. Library copy states that clips stream online and saved items are bookmarks. Old asset note references resolve through the local metadata catalogue to current cloud URLs; they are never treated as missing personal files.
