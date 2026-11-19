# Vimi photographic visual revision

## Request and result

The user disliked the first palette and the strong AI/comic illustration. The chosen working direction is neutral black/white/gray, natural photographic imagery and quieter native composition. An optional palette preference was requested; without a different selection, the stated monochrome direction was used.

- Replaced the illustrated launcher icon with an original monochrome typographic mark, including all Android density PNGs and the 1024px store source.
- Replaced character illustrations with two separately generated photographic dance assets, used in the welcome and challenge sections. Faces, ordinary anatomy, clothing, lighting and source/optimized images were visually inspected. Images depict fictional adults and do not claim real community membership.
- Removed character backgrounds from forms, chat, profile and the four-tab shell. Removed paper textures and cream/lime colors from active UI.
- Unified active typography on bundled DM Sans. The old display font and its notice remain recoverable in the repository but are not registered/bundled for the active UI.
- Replaced heavy decorative glyphs with an original 32-glyph line atlas; corrected native display geometry to the actual optical bounds of each raster glyph.
- Reworked welcome/photo/heading/action spacing, primary versus secondary buttons, the challenge entry and operational titles.
- Preserved existing callbacks, routes, account state, player interactions, social rules and purchase flows. This task did not require backend changes.

## Files and provenance

Implementation: `lib/design/vimi_ui.dart`, `lib/features/auth/auth_pages.dart`, `lib/features/community/community_pages.dart`, `lib/features/shell.dart`, supporting style call sites, Android resource colors and launcher PNGs, font registration and `pubspec.yaml`.

Current original sources: `assets/brand/sources/editorial-v2/`; prompts: `assets/brand/generation-prompts-v2.json`; runtime rasters: `assets/ui/`; inventory: `assets/brand/asset-inventory.json`. Original rejected art and previous UI source are in `docs/design-history/2026-11-18-editorial-v1/` and are excluded from the app bundle.

`docs/design-preview/vimi-welcome-v2-concept.png` is a generated design reference using the new photo/mark. Its typography and device framing are illustrative. It is not a capture of Flutter, an emulator or a real device, and it is never used as the running page.

## Verification

Dart formatter parsed the 19 source files. JSON/XML parsed; literal asset references and local imports resolve. The six current runtime rasters decode. Old illustrated raster references and old cream/lime values were checked out of active source/resources. Current bundled assets, DM Sans/notice, data and legal copy total 1,452,306 bytes (about 1.45 MB), excluding native launcher PNGs and compiled/runtime overhead. Source and preview files do not enter the app bundle.

No Flutter build, analyzer, tests, app launch, emulator, device, native screenshot capture, UI interaction validation or final APK/AAB size check was run.
