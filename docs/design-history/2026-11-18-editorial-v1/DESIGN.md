# Vimi design system

Primary surface: Explore on Floor; Operate in Studio/Inbox; Configure in account forms. Cream paper, ink and a restrained lime accent reflect daylight rehearsal rather than concert neon.

| Role | Value |
| --- | --- |
| ground | #F4F2EA |
| ink | #22251F |
| secondary ink | #606455 |
| action | #CBE85B |
| quiet line | #D9DCCF |
| error | #923B32 |
| display | Space Grotesk, 32/38 or 44/48, 600–700 |
| body | DM Sans, 16/24 |
| label | DM Sans, 14/20, 600 |
| spacing | 4, 8, 12, 16, 24, 32, 48 |

Use native Flutter layout/text/semantics with original raster artwork. Four distinct portrait illustrations anchor Floor, Studio, Inbox and Me. A generated 8×4 transparent icon atlas covers navigation and controls. The original button skin and paper asset carry branded controls and panels. Do not use Material/Cupertino icon fonts, programmatic artwork, emoji icons or default app-owned dialogs. Genuine OS media selection, permissions and Google Play payment sheets remain platform-owned.

Compact widths use four bottom destinations; expanded widths use a labeled side navigation, centered readable content and wider media grids. Respect Android predictive Back, gesture and display cutout insets, keyboard, text scaling and reduced motion. Every interactive region is at least 48 logical pixels. Media does not autoplay. Background and navigation transitions pause the single active video.

Auth is a single short form; failed submissions preserve input. A new community has honest empty states, authored challenge prompts and a publishing action, not fictitious activity. Error feedback offers retry, coins never use invented store prices, and every paid pack has visible deliverables before spending.

Runtime render, font scale, Android gestures and device behavior have not been verified.
