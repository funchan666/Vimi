# Vimi media inventory · neon social

The brand system retains seven original rasters. Four original assets were produced with the built-in host image tool for the explicit neon-gradient revision; the three utility rasters are retained original project assets. Those brand photographs depict fictional adults and are never claimed member uploads. The publisher subsequently supplied **55 photos and ten videos**, confirmed commercial distribution/likeness/audio rights, and required every valid item to be used. All 65 are registered in the native video library and profile image library; the full source/optimized/path/entry ledger is [SUPPLIED_MEDIA.md](media/SUPPLIED_MEDIA.md), with exact hashes and dimensions in `media/supplied-media-inventory.json`.

| Asset | Original source bytes | Runtime bytes | Role |
| --- | ---: | ---: | --- |
| glyphs-clean | 421,014 | 264,278 | 32 original clean utility glyphs |
| control-fill | 1,048,996 | 212,910 | original clean button skin |
| surface-clean | 978,729 | 507,484 | original untextured panel surface |
| neon-spectrum | 1,348,845 | 21,786 | Original pink-violet-cyan gradient for actions, filters and ambient backgrounds |
| neon-welcome | 2,046,195 | 188,292 | Original neon-lit adult dance welcome photograph |
| neon-floor | 1,932,437 | 133,488 | Original neon-lit dance challenge cover |
| vimi-logo | 318,124 | 318,124 | Publisher-supplied PNG for startup, Android launcher, Play Store and local policy-site branding |

The current authoritative mapping is `assets/brand/asset-inventory-v3.json`. New original PNGs are preserved under `assets/brand/sources/neon-v3/`, previous utility sources under `assets/brand/sources/editorial-v2/`. Prompts are in `assets/brand/generation-prompts-v3.json` and `garden-gpt-image-2/prompt/vimi-neon-*-20261119.md`. Sources and prompts are excluded from the app bundle.

The Flutter logo and the Play Store image match the submitted PNG byte for byte. Android launcher densities resize the same source. The retired gradient monogram remains documented in the historical inventories. Utility rasters retain their existing encoding, and the original gradient still supplies primary actions, selected filters, navigation and tinted message/profile panels.

Source and optimized new photography, the original gradient/mark and the 48px launcher were visually inspected. Generated people retain photographic skin, ordinary clothes and credible anatomy; no manga/comic art is used. App crops and actual native text/controls have not been rendered or exercised.

`docs/design-preview/vimi-neon-floor-v3-concept.png` is a generated visual reference with illustrative names/avatars/post content. It is not a Flutter screenshot and is not loaded as a page or inserted as fake community data. The running community queries real profiles/posts and keeps meaningful loading, empty and error states. Supplied-library people are not inserted as registered members; profile images change only when a member explicitly selects and saves one.

Rejected illustration and monochrome snapshots are preserved under `docs/design-history/`, outside the bundle. Only DM Sans and its OFL notice are registered as fonts. Original supplied files are preserved in Downloads and byte-verified backups under ignored `ProjectMaterials/Supplied/Originals`; only optimized content is registered. Static/full-stream decoding, frame timing and unchanged audio-packet checks are in `media/supplied-media-quality.json`. Native/runtime results are recorded separately in `VERIFICATION.md`; the original design-pass concept is not runtime evidence.
