# progress.md — Live Build Tracker (Pendi, Flutter)

Agent: update this file at the end of every commit. Status key: `[ ]` todo, `[x]` done, `[!]` blocked (add reason).
Log line format: `YYYY-MM-DD · Fxx · <short hash> · one-line note`

## Current state
- Next commit: **F08**
- Gate status: green
- Mode: demo (no env keys set)
- History: commits C01–C12 built a Next.js version (foundation + reading planner). On 2026-11-21 the user switched the app to **Flutter** and renamed it **Pendi**. That work is preserved on branch `nextjs-web`; `main` restarts at F01.

## Checklist

### Phase 0 — Foundation
- [x] F01 chore: replace Next.js scaffold with Flutter app
- [x] F02 feat(ui): design tokens, fonts, theme mode
- [x] F03 feat(ui): core primitives
- [x] F04 feat(shell): tab scaffold with rail and bottom bar
- [x] F05 feat(data): db interface, demo adapter, supabase adapter
- [x] F06 feat(auth): google sign-in and auth gate
- [x] F07 feat(domain): date utilities with timezone tests

### Phase 1 — Reading Planner
- [ ] F08 feat(domain): reading quota planner
- [ ] F09 feat(reading): sources and items repository
- [ ] F10 feat(integrations): link extractor for course and blog pages
- [ ] F11 feat(reading): add-source sheet with page picker
- [ ] F12 feat(reading): reading screen and per-source progress

### Phase 2 — CP Tracker
- [ ] F13 feat(domain): cp daily picker and streak
- [ ] F14 feat(cp): list import and active list management
- [ ] F15 feat(integrations): codeforces solved-status sync
- [ ] F16 feat(cp): cp screen with daily 2, streak, and review queue

### Phase 3 — Work Hub
- [ ] F17 feat(hackathons): repository and list view
- [ ] F18 feat(hackathons): detail view with timeline and checklist
- [ ] F19 feat(research): projects, daily log, and task inbox
- [ ] F20 feat(research): papers, ideas, and experiments
- [ ] F21 feat(research): weekly summary generator

### Phase 4 — College
- [ ] F22 feat(college): courses, attendance, and skip calculator
- [ ] F23 feat(college): tasks for assignments, exams, and clubs
- [ ] F24 feat(gcal): calendar sync read and write

### Phase 5 — Glue
- [ ] F25 feat(today): unified today screen
- [ ] F26 feat(capture): quick capture sheet and inbox
- [ ] F27 feat(habits): simple habits with streaks
- [ ] F28 feat(notes): evening review

### Phase 6 — Polish and Ship
- [ ] F29 feat(app): launcher icons, splash, and offline cache
- [ ] F30 feat(settings): profile, timezone, codeforces handle, data export
- [ ] F31 test(e2e): smoke flows
- [ ] F32 chore: a11y, performance, and empty-state pass
- [ ] F33 docs: README, setup guide, and handover

## Decisions
<!-- Agent: log every judgment call here. Format: Fxx · decision · why -->
- Seed reading sources: designed-to-scale.vercel.app and saadho.arushk.tech, 30 days each.
- CP lists are imported from pasted problem lists or URLs (no scraping); solved status verified through the Codeforces public API.
- "Today's reading quota" is computed on read, not stored, so missed days redistribute automatically.
- 2026-11-21 · switched from Next.js PWA to Flutter (Android first, web build for checks) and renamed to Pendi · user request
- Flutter app lives at the repo root next to `supabase/` · one project, simplest tooling
- No code generation (freezed/json_serializable/riverpod_generator) · keeps the gate fast and the code readable
- Calendar and Codeforces sync run on app open and pull-to-refresh instead of server cron · no server code needed for a single-user app
- Carried from the Next.js build (still valid):
  - `0001_init.sql` schema incl. `profiles.id`, `done_at` columns, `hackathon_milestones.gcal_event_id`, `daily_notes`; verified on Postgres with RLS isolation
  - Light theme `muted` #6E5E4C for AA contrast on cream
- F03 · light `accent` darkened again to #A14A07 · #B45309 measured 4.26:1 on cream in Flutter's contrast guideline test
  - Reading quota fixed at start of local day; carried-over = behind an even pace
  - Link extractor: HTML link order + titles first, sitemap-only pages appended; designed-to-scale is a hash-routed SPA so its 40 lessons are bundled; saadho seed = its 141 `/topics/*` pages
  - Live-network tests opt-in only
- F04 · wordmark shown as PNG (rendered from the SVG with rsvg-convert) · flutter_svg conflicts with xml ^7 needed by the extractor
- Brand: Geist SemiBold "pendi" wordmark with an amber i-dot; icon = "p" + amber dot (`assets/brand/`, generator `tool/make_logo.py`)

## Blockers
<!-- Agent: exact error, what was tried, what the user must do. -->
- none

## Backlog (discovered work, not in plan)
- none

## Performance and accessibility (F32)
- Today first frame (profile): –  Guideline tests: –

## Log
<!-- newest at bottom -->
- 2026-11-21 · C01–C12 · c9ad12e · Next.js version (now on branch `nextjs-web`)
- 2026-11-21 · F01 · b3adb9d · flutter create at root, strict lints, env.example.json, seeds/fixtures moved, gate script
- 2026-11-21 · F02 · 49ab657 · PendiColors ThemeExtension, Geist fonts, persisted theme mode; tests
- 2026-11-21 · F03 · 4d323ae · 11 primitives + PageScaffold + gallery; a11y guideline tests in both themes
- 2026-11-21 · F04 · 19d4295 · StatefulShellRoute, 5 stub tabs, rail ≥600dp with wordmark; tests at 375/1280
- 2026-11-21 · F05 · f2a1495 · Db interface; DemoDb mirrors SQL defaults/uniques/cascades; SupabaseDb; Result + validators
- 2026-11-21 · F06 · 688c335 · google_sign_in 7 + signInWithIdToken w/ calendar scope; redirect tested; demo banner
- 2026-11-21 · F07 · 58d71ca · dates.dart on timezone pkg; TS suite ported + weekStart/labels

## Handover (written in F33)
<!-- What works · what is mocked · env vars to set · 3 manual steps (Supabase project, Google OAuth client IDs, release APK build) -->
