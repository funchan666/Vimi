# Vimi design system · photographic revision

The user rejected the first version's colors, strong AI illustration feel and comic characters. The replacement uses monochrome photographic imagery sparingly, clean neutral surfaces and straightforward native typography. This document supersedes the cream/lime/paper illustration direction preserved in `docs/design-history/2026-11-18-editorial-v1/`.

| Role | Value |
| --- | --- |
| background | #F8F9FB |
| panel / foreground | #FCFCFD |
| primary ink / actions | #15171B |
| secondary ink | #666D77 |
| selected control surface | #ECEEF1 |
| quiet line | #E0E3E8 |
| error | #AD3543 |
| type family | DM Sans, 400 / 600 / 700 |
| display | 40 / 44.8 |
| headline | 32 / 37.1; welcome 34 / 38.1 |
| body | 16 / 24 |
| labels | 14 / 18.2 |
| spacing | 4, 8, 12, 16, 24, 28, 32, 40 |

Welcome is a single photo followed by a compact wordmark, short headline, one primary action and two quiet secondary actions. Expanded layouts place the photo beside the form content. The Floor uses a separate wider rehearsal photo above a concise challenge entry and the genuine community feed. Messages, profile, settings and forms use plain, untextured surfaces; no faded figures sit behind working UI.

Two original host-generated photographic assets depict fictional adult dancers. They are visual brand material, not claimed photographs of actual members or actual uploaded covers. No cartoon/comic characters, paper grain, fluorescent green, cream color cast, neon, glossy decoration or fake engagement are used in this revision.

The typographic launcher mark and 32 original utility glyphs replace the illustrated icon and heavy glyphs. Each glyph is displayed from measured regions of the original raster atlas, retaining clear line weight and optical centering; no replacement artwork is drawn in code. Controls use original raster skins with native text, layout, focus, semantics and interaction. OS media selection, permission and Google Play payment flows remain genuine.

Compact navigation retains Floor, Studio, Inbox and Me; expanded navigation retains the labeled side rail. Touch areas are at least 48 logical pixels. Insets, keyboard handling, text scaling, route actions and video pause contracts are retained.

Source and resource inspection only. `docs/design-preview/vimi-welcome-v2-concept.png` is an image-generated visual reference, not an app screenshot. No Flutter build, analyzer, tests, emulator, device run or runtime visual acceptance was performed.
