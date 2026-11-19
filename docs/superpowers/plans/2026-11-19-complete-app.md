# Vimi Complete Functional Journeys Implementation Plan

> **Execution:** Follow the user-authorized method and the host's available tools. Track concrete tasks with checkboxes. No uninstalled skill is required.

**Goal:** Complete Vimi's native neon-styled secondary pages and verify meaningful account, publishing, community, messaging, practice and wallet journeys.

**Architecture:** Preserve the Flutter widget/repository/controller structure and existing Supabase project. Use shared original raster controls and meaningful native page layouts; repair business-state transitions at their owning layer. Add focused widget/storage tests, database checks with rollback and Android integration tests, keeping their evidence distinct.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Android, Supabase Flutter 2.18.3, existing locked plugins, Flutter SDK test packages.

**Spec:** `PRODUCT.md`, `DESIGN.md`, `docs/FUNCTIONAL_ACCEPTANCE.md`, current user request.

## Global Constraints

- Flutter/Dart Android, English, application ID `com.vimistudio.vimi`.
- Keep the approved midnight-violet and pink/violet/cyan neon identity on primary and secondary flows.
- Original project raster art; genuine OS permissions/media picker/Play sheets; no fake members, follows, posts, replies or purchase success.
- Use Primary Supabase project `hgxbfgcdfsalavdfyvjr`; no other project changes or billable new resources.
- User explicitly requested runnable verification for this task; no publication, release signing or real purchases without the necessary publisher setup.

## Review Focus

- Leaving/reopening editors must preserve real drafts; failed saves and account changes must not lose or leak data.
- Cancel/retry/double-tap on uploads, account actions, follows, messages and paid unlocks must not duplicate results.
- Empty/loading/error/blocked/deleted states need truthful, reachable recovery paths.
- Larger text, keyboard, narrow and expanded screens must keep complete secondary actions usable.
- A matching page or successful database deployment is not end-to-end evidence; separate credential/configuration-dependent acceptance.

### Task 1: Establish runnable baseline

**Files:** `analysis_options.yaml`, `pubspec.yaml`, current Dart sources, `docs/verification/2026-11-19/`.

- [x] Exclude recoverable historical source snapshots from active analysis and add SDK test dependencies.
- [x] Run analyzer and Android debug compilation; fix actual source/toolchain failures.
- [x] Start an available Android emulator without wiping its data and record actual device properties (API 35, ARM64, 1080 × 2400, density 420).

### Task 2: Complete business-state and account/media paths

**Files:** `lib/core/`, account/community/profile/studio features, focused `test/` cases.

- [x] Inspect all existing callbacks/routes against the acceptance matrix; implement named gaps in existing flows.
- [x] Verify failed/serialized saves, drafts/reopening, account isolation, feed pagination and refresh without silent data loss; record the remaining bounded-history reads.
- [x] Complete account verification/recovery navigation and media edit/publish cleanup while retaining genuine services.
- [x] Verify the owning changes through storage/widget tests and relevant database/API checks.

### Task 3: Finish consistent secondary screens and safety/operations

**Files:** shared design components, community/messages/profile/wallet/studio secondary pages, required server definitions.

- [x] Carry neon controls, responsive forms, status/result/loading/empty/error states through every secondary route.
- [x] Complete discover/profile/follow/chat/read/block/report/settings paths; add necessary operational/status views without fictional data.
- [x] Keep moderation role server-managed and billing visibly unavailable until genuine Play setup exists.
- [x] Verify UI route actions and negative permission/relationship cases.

### Task 4: Exercise and repair complete journeys

**Files:** `test/`, `integration_test/`, `supabase/tests/`, verification report/screenshots.

- [x] Run focused automated checks with meaningful persistence/result assertions.
- [x] Exercise database business/RLS invariants using isolated temporary data and rollback/cleanup.
- [x] Build/install and run Android integration flows; inspect actual emulator screenshots at normal and larger text/expanded widths.
- [x] Repair observed defects, rerun affected checks and record concrete pass/fail/configuration-dependent results.
- [x] Update the handoff and acceptance matrix; provide usable debug artifact and actual screenshots where available.

## Publisher-dependent acceptance

Google Play product creation, verifier credential, upload signing, physical devices, production recovery SMTP and public publisher/policy details remain outside the verified local delivery. Final native video/recovery and distributable artifact results are recorded in VERIFICATION.md.
