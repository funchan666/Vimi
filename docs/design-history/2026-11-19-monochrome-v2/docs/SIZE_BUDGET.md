# Vimi size budget

Measured assets registered for the photographic monochrome revision:

| Class | Bytes |
| --- | ---: |
| ui | 1,201,638 |
| fonts | 244,646 |
| data | 1,480 |
| legal | 4,542 |

Total media/fonts/data/legal: 1,452,306 bytes (about 1.45 MB). This includes active DM Sans and its license text and excludes unregistered legacy fonts, generated source PNGs, the Play listing source, prompts, design previews, the historical art/source snapshot, docs and project tooling. Android launcher density resources are additional small PNGs. The active inventory is recorded in `resource-inspection.json` and `assets/brand/asset-inventory.json`.

There is no bundled content-video collection, ZIP/WebView payload or duplicate raw media directory. User uploads are private Supabase objects; personal rehearsal selections are retained in account-scoped app storage and are not APK resources. Further size savings must preserve the original art and legibility.

The skill target remains to keep the eventual distributable as small as practical, preferably below 50 MB. No APK/AAB, installed app or store download has been measured; Flutter engine, compiled code, native plugins, ABI splits, signing and delivery overhead are unknown. The source asset total does not establish the final package size. No build was run.
