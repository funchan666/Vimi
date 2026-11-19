# Vimi size budget · neon social

Measured assets registered in the current Flutter manifest:

| Class | Bytes |
| --- | ---: |
| ui | 1,614,206 |
| fonts | 244,646 |
| data | 48,738 |
| legal | 15,672 |
| bundled supplied media | 0 |

Total: 1,923,262 bytes. This includes active DM Sans and its license notice, all five English legal texts and the lightweight cloud catalogue for all 65 supplied source items; the 128 media files are served from Supabase. It excludes source PNGs, the listing source, concepts, history, prompts, the separate policy website and unused fonts. Native Android launcher density PNGs are additional resources. Current totals are in `verification/2026-11-19/media-resources.json`; earlier visual/Play-pass totals remain historical records.

The original neon photographs, gradient, mark and utility art remain in use. The compact-control refinement adds one 245,234-byte lossless original atlas. The publisher-supplied content is now served from public Supabase Storage. Practice notes keep stable IDs; old asset references resolve to the cloud without rewriting user data. Project media backups were deleted at the publisher’s explicit request. The source-to-runtime ledger is `media/SUPPLIED_MEDIA.md`.

Private member uploads are Supabase objects and private rehearsal videos are account-scoped device files, not APK resources. The new gradient is reused as one raster for native controls/backgrounds rather than duplicated per page.

## Measured Android artifacts · November 19

| Artifact | Bytes | Mode |
| --- | ---: | --- |
| app-arm64-v8a-debug.apk | 95,591,706 | debug |
| app-armeabi-v7a-debug.apk | 74,680,868 | debug |
| app-debug.apk | 205,384,289 | debug |
| app-x86_64-debug.apk | 81,597,893 | debug |
| Vimi-1.0.0-arm64-preview.apk | 36,909,069 | profile |

Debug rows are historical measurements. The current main-entrypoint ARM64 profile preview is **36,909,069 bytes**, below the 50,000,000-byte soft target. The prior bundled preview was 67,253,150 bytes; the decrease is 30,344,081 bytes. After the user approved cloud delivery, all 128 local content files and their four Flutter asset registrations were removed only after every public download matched its optimized source and the Android suite streamed/decoded all 65 source items. The cloud files are the exact 30,324,892 optimized bytes: no additional compression, cropping, truncation or audio removal occurred. Original and optimized project media backups were subsequently deleted at the publisher’s explicit request. Library viewing now requires internet; private journaling and bookmark metadata remain local.


The profile APK uses a local test signature and includes development/profile overhead. It is not a store download-size estimate. No upload-signed release, AAB or Play delivery size is claimed. SHA-256 and private-credential exclusion are in `verification/2026-11-19/artifacts.json`; `cloud-library/apk-packaging.json` confirms that no supplied media files enter the current APK and that every bundled UI/data/legal file matches source. `cloud-library/public-object-verification.json` checks all cloud media bytes. The previous 36,522,345-byte preview, which did not contain this supplied library, remains an earlier measurement in `artifacts-before-media.json`.

`verification/2026-11-19/artifacts-before-cloud-library.json` preserves the immediately preceding 67,253,150-byte snapshot. No published Play delivery-size estimate is implied.
