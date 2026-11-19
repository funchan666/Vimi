# Vimi media inventory · neon social

The current runtime includes seven original rasters. Four new original assets were produced with the built-in host image tool for the explicit neon-gradient revision; the three utility rasters are retained original project assets. New photographs depict fictional adults and are brand/challenge imagery, never claimed member uploads. No commercial music, idol images, external stock photographs or dance videos were downloaded.

| Asset | Original source bytes | Runtime bytes | Role |
| --- | ---: | ---: | --- |
| glyphs-clean | 421,014 | 264,278 | 32 original clean utility glyphs |
| control-fill | 1,048,996 | 212,910 | original clean button skin |
| surface-clean | 978,729 | 507,484 | original untextured panel surface |
| neon-spectrum | 1,348,845 | 21,786 | Original pink-violet-cyan gradient for actions, filters and ambient backgrounds |
| neon-welcome | 2,046,195 | 188,292 | Original neon-lit adult dance welcome photograph |
| neon-floor | 1,932,437 | 133,488 | Original neon-lit dance challenge cover |
| neon-mark | 1,330,998 | 40,734 | Original gradient Vimi monogram / Android launcher source |

The current authoritative mapping is `assets/brand/asset-inventory-v3.json`. New original PNGs are preserved under `assets/brand/sources/neon-v3/`, previous utility sources under `assets/brand/sources/editorial-v2/`. Prompts are in `assets/brand/generation-prompts-v3.json` and `garden-gpt-image-2/prompt/vimi-neon-*-20261119.md`. Sources and prompts are excluded from the app bundle.

New full-color WebP uses quality 94 (96 for the mark). Utility rasters retain their existing lossless/alpha encoding. Only conversion, resizing and compression derived runtime files from original generated art; no replacement icons, illustrations, gradients or textures were drawn in code. Native layout clips/displays the original gradient for primary actions, selected filters, navigation and tinted message/profile panels. Atlas display uses the previously measured raster regions. All launcher densities derive from the new mark.

Source and optimized new photography, the original gradient/mark and the 48px launcher were visually inspected. Generated people retain photographic skin, ordinary clothes and credible anatomy; no manga/comic art is used. App crops and actual native text/controls have not been rendered or exercised.

`docs/design-preview/vimi-neon-floor-v3-concept.png` is a generated visual reference with illustrative names/avatars/post content. It is not a Flutter screenshot and is not loaded as a page or inserted as fake community data. The running app queries real profiles/posts and keeps real loading, empty and error states.

Rejected illustration and monochrome source/asset snapshots are preserved under `docs/design-history/`, outside the bundle. Only DM Sans and its upstream OFL notice remain registered as fonts. No build, tests, app launch, emulator or device check was performed.
