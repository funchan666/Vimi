# Vimi neon social revision · November 19, 2026

## User brief

The user subsequently approved this direction on November 19, 2026: “这个不错，就按这个方向来。” It is the accepted Vimi visual baseline. The verification limitations below still apply.

The user rejected the black-white-gray direction as unattractive and insufficiently social, and explicitly requested a cool neon-gradient effect. The new direction uses a deep violet base with bright orchid-pink/violet/cyan gradients, expressive dance imagery and clearer people/posting/discovery hierarchy. The requirement for complete functional journeys remains in `FUNCTIONAL_ACCEPTANCE.md`; a visual revision does not replace that requirement.

## Implementation

- Replaced shared light roles with a coherent dark Material color scheme; kept light main/secondary text, colored focus/error states and native field/keyboard semantics.
- Added original gradient-filled primary actions, selected genre controls, navigation accents, gradient monogram and all launcher density resources. System-bar icon contrast and native launch/normal backgrounds follow the dark theme.
- Replaced monochrome welcome/challenge photography with two separately generated neon-lit adult dance images, visually inspected at source/optimized quality. The existing v silhouette was explicitly preserved when generating its neon treatment.
- Made the Floor compact and social: Post is visible, Challenges opens existing challenge journeys, actual dancers load through `searchDancers`, their avatars open actual profiles, and genre filtering leads into the genuine post collection. The dancer strip handles loading, empty/error/retry states and reloads on account/revision changes. No seeded members, posts or engagement were added.
- Carried the theme into account forms, content/detail/publish pages, practice, messages (including outgoing panels), profile, settings, wallet and feedback. Existing inputs, routes, persistence, media and payment contracts remain in place.
- Reduced challenge-banner height while letting native content determine its actual size, avoiding a fixed-height text overlay that would clip larger fonts. Welcome keeps scrolling and the expanded two-column layout; the main navigation retains the original expanded rail.

Affected source is in `lib/design/vimi_ui.dart`, `lib/main.dart`, `lib/features/shell.dart`, auth/community/studio/messages/profile/wallet UI files, plus Android resource colors/styles and launcher PNGs. No Supabase migration, function deployment, product ID, billing enablement, permission contract or project identity changed.

## Art, provenance and recovery

Four new original runtime rasters: `neon-spectrum`, `neon-welcome`, `neon-floor`, `neon-mark`. The retained original glyph atlas and control/panel skins make seven active raster assets in total. New PNGs are in `assets/brand/sources/neon-v3/`; prompt records are in `assets/brand/generation-prompts-v3.json` and `garden-gpt-image-2/prompt/vimi-neon-*-20261119.md`. Runtime references use optimized WebP in `assets/ui/`.

Retired runtime files were checked against literal asset references and the then-current snapshot before removal. The obsolete snapshot was later removed from the checkout.

`docs/design-preview/vimi-neon-floor-v3-concept.png` is a generated social-home visual reference. Its Mina/Jae/Ari/Sol names, avatar treatment and post are illustrative design content, not app data or actual members. It is not a Flutter runtime screenshot and is not used as a page background or working screen. Native typography/layout/scroll positions can differ until actual device validation is authorized and performed.

## Evidence and boundary

At this revision, Dart formatting parsed 19 source files. Static inspection covered JSON/XML, literal assets, local imports, raster decoding and route callbacks. Contrast calculations sampled flat semantic roles and gradient pixels. See `contrast-inspection-v3.json` and `resource-inspection.json`.

Registered images, active DM Sans/license, data and legal text total 1,619,640 bytes; this excludes native launcher PNGs and Flutter/native compilation/delivery overhead. It is not an APK/AAB size measurement.

No Flutter build, analyzer, unit/integration tests, app launch, emulator/device, native UI screenshot, actual font-scaling/layout acceptance, two-account chat, account/media operations or Play transaction was performed. The existing configuration-dependent acceptance work remains in `HANDOFF.md`. This revision cannot be called end-to-end verified.
