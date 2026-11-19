# Vimi Android Implementation Plan

> **Execution:** Follow the user-authorized method and the host’s available tools. Track concrete tasks with checkboxes. No uninstalled skill is required.

**Goal:** Build Vimi, an English Flutter Android dance social app with Supabase and Google Play coins.

**Architecture:** Flutter screens share an application controller and a typed repository. Supabase owns authentication, social data, private media and immutable money records; device preferences own offline practice drafts. Edge Functions validate privileged operations and Google Play receipts.

**Tech Stack:** Installed Flutter 3.44.0 / Dart 3.12.0, supabase_flutter 2.18.3 pinned to the inspected v2 API, in_app_purchase 3.3.0, Android SDK tools, Supabase Postgres and Deno Edge Functions.

**Spec:** PRODUCT.md and DESIGN.md.

## Global Constraints

- Android only; Flutter widgets and Dart; com.vimistudio.vimi; English.
- Original raster icons/illustrations/button skins; OS-owned flows remain real.
- No builds, tests, analyze, emulator, device run, fake payments, fabricated followers or messages.
- No service-role or Play private key in mobile source; new public tables use RLS.

## Review Focus

- Session changes must not leak another account's data or lose a pending purchase.
- Retry after credit/consume failure must never double-credit or acknowledge an unverified token.
- Blocks and removed follows must prevent later sends on the server.
- Private pending uploads must not be publicly readable through Storage.
- Narrow screens, large text, keyboard and route changes must preserve drafts and pause media.

## Tasks

- [x] Inspect the empty checkout, local Flutter SDK, skill constraints and cloud destinations.
- [x] Create Android configuration, locked dependencies, original assets and typed application shell.
- [x] Implement RLS-protected schema, Storage, challenges, social RPCs and wallet transaction contracts.
- [x] Implement Auth, posts/comments, private-media upload, profile/relationships, report/block and realtime inbox.
- [x] Implement offline practice journal, player controls and real coin-unlocked drill packs.
- [x] Implement Play receipt Edge Function, retryable mobile purchase handling and product/configuration guide.
- [x] Deploy to the authorized independent Supabase project; inspect deployed definitions and advisors.
- [x] Complete static diff/resource/contract review and state unperformed runtime checks.


Implementation and static handoff tasks are complete at their stated scope. Auth settings, Play/operator credentials and runtime acceptance remain the explicit publisher tasks in docs/HANDOFF.md; they are not marked as executed by these implementation checkboxes.
