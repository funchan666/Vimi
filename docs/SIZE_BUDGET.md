# Vimi size budget · neon social

Measured assets registered in the current Flutter manifest:

| Class | Bytes |
| --- | ---: |
| ui | 1,368,972 |
| fonts | 244,646 |
| data | 1,480 |
| legal | 14,591 |

Total: 1,629,689 bytes. This includes active DM Sans and its license notice, all five English legal texts, and excludes source PNGs, the Play listing source, design concepts, history, prompts, the separate policy website and unregistered legacy fonts. Native Android launcher density PNGs are additional resources. Current registered-asset totals and bundled-policy byte checks are in `verification/2026-11-19/play-resources.json`; `resource-inspection.json` retains the earlier visual-pass inventory.

The two original neon photographs, gradient and mark replace the prior monochrome photos/mark. The removed runtime files were byte-checked against the exact recoverable history snapshot before removal; active literal references were checked first. Original utility art remains in use. No duplicate raw media folder or bundled content-video collection is introduced.

Private member uploads are Supabase objects and private rehearsal videos are account-scoped device files, not APK resources. The new gradient is reused as one raster for native controls/backgrounds rather than duplicated per page.

## Measured Android artifacts · November 19

| Artifact | Bytes | Mode |
| --- | ---: | --- |
| app-arm64-v8a-debug.apk | 95,591,706 | debug |
| app-armeabi-v7a-debug.apk | 74,680,868 | debug |
| app-debug.apk | 205,384,289 | debug |
| app-x86_64-debug.apk | 81,597,893 | debug |
| Vimi-1.0.0-arm64-preview.apk | 36,522,345 | profile |

Debug rows above are historical pre-hardening measurements. The current recommended ARM64 profile preview is below the 50,000,000-byte target without changing the original UI assets or removing functionality. It uses a local test signature. The larger debug builds carry development overhead and are not store download sizes. No upload-signed release, AAB or Play delivery measurement is claimed. SHA-256 values and credential-exclusion results are in `verification/2026-11-19/artifacts.json`.
