# Vimi media inventory

Six current runtime rasters were produced with the built-in image generator, copied into the project, optimized and referenced by the app. This photographic monochrome revision replaces the original comic/cream/lime direction. No user media was supplied; no external photographs, idol images, music or dance videos were downloaded. The photographic assets depict fictional adult dancers, not actual registered community members.

| Asset | Source bytes | Runtime bytes | Role |
| --- | ---: | ---: | --- |
| welcome-photo | 1,954,104 | 120,746 | photographic welcome image |
| floor-photo | 1,891,637 | 74,668 | photographic challenge cover |
| vimi-mark | 1,128,975 | 21,552 | monochrome typographic mark / launcher source |
| glyphs-clean | 421,014 | 264,278 | 32 original utility glyphs in a transparent atlas |
| control-fill | 1,048,996 | 212,910 | clean original button skin |
| surface-clean | 978,729 | 507,484 | untextured original panel surface |

Runtime UI total: 1,201,638 bytes. Current PNG sources are preserved under `assets/brand/sources/editorial-v2/` and excluded from app bundling. Prompt provenance is in `assets/brand/generation-prompts-v2.json`; dimensions and roles are in `assets/brand/asset-inventory.json`. The previous art and source snapshot remain in `docs/design-history/2026-11-18-editorial-v1/`, also excluded from the bundle.

Images were decoded and visually inspected. Photographic WebP assets use quality 93; the glyph atlas, control and panel skins use lossless encoding. Alpha is preserved where present. Only transparent outer margins were trimmed from the button; no replacement artwork was drawn in code. Android launcher sizes are derived from the new original mark. The atlas is displayed through measured clipping/translation regions recorded in `assets/brand/glyph-regions-v2.json`, rather than regenerated with paths. Shared panels and controls apply solid neutral tints to the original skins.

Only DM Sans and its actual upstream OFL notice are registered/bundled. The old font files remain recoverable but are not active assets. Runtime app layout and control rendering were not observed. `docs/design-preview/vimi-welcome-v2-concept.png` is an image-generated visual reference, not a Flutter screenshot. No build, tests, app launch or device validation was performed.
