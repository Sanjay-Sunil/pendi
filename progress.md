# progress.md — Live Build Tracker

Agent: update this file at the end of every commit. Status key: `[ ]` todo, `[x]` done, `[!]` blocked (add reason).
Log line format: `YYYY-MM-DD · Cxx · <short hash> · one-line note`

## Current state
- Next commit: **C13**
- Gate status: green
- Mode: demo (no env keys set)
- Session 1 stopped after C12 (context budget). UI checks: `pnpm build && scripts/serve-smoke.sh /route ...`

## Checklist

### Phase 0 — Foundation
- [x] C01 chore: bootstrap Next.js app with tooling
- [x] C02 feat(ui): design tokens, fonts, theme toggle
- [x] C03 feat(ui): core primitives
- [x] C04 feat(shell): app layout with rail and mobile tab bar
- [x] C05 feat(data): supabase clients, demo-mode adapter, and migration 0001
- [x] C06 feat(auth): google sign-in and route protection
- [x] C07 feat(domain): date utilities with timezone tests

### Phase 1 — Reading Planner
- [x] C08 feat(domain): reading quota planner
- [x] C09 feat(reading): sources and items data layer with actions
- [x] C10 feat(integrations): link extractor for course and blog pages
- [x] C11 feat(reading): add-source flow with page picker
- [x] C12 feat(reading): reading screen and per-source progress

### Phase 2 — CP Tracker
- [ ] C13 feat(domain): cp daily picker and streak
- [ ] C14 feat(cp): list import and active list management
- [ ] C15 feat(integrations): codeforces solved-status sync
- [ ] C16 feat(cp): cp screen with daily 2, streak, and review queue

### Phase 3 — Work Hub
- [ ] C17 feat(hackathons): data layer and list view
- [ ] C18 feat(hackathons): detail view with timeline and checklist
- [ ] C19 feat(research): projects, daily log, and task inbox
- [ ] C20 feat(research): papers, ideas, and experiments
- [ ] C21 feat(research): weekly summary generator

### Phase 4 — College
- [ ] C22 feat(college): courses, attendance, and skip calculator
- [ ] C23 feat(college): tasks for assignments, exams, and clubs
- [ ] C24 feat(gcal): calendar sync read and write

### Phase 5 — Glue
- [ ] C25 feat(today): unified today screen
- [ ] C26 feat(capture): quick capture palette and inbox
- [ ] C27 feat(habits): simple habits with streaks
- [ ] C28 feat(notes): evening review

### Phase 6 — Polish and Ship
- [ ] C29 feat(pwa): manifest, icons, offline shell
- [ ] C30 feat(settings): profile, timezone, codeforces handle, data export
- [ ] C31 test(e2e): smoke flows
- [ ] C32 chore: a11y, performance, and empty-state pass
- [ ] C33 docs: README, deploy guide, and handover

## Decisions
<!-- Agent: log every judgment call here. Format: Cxx · decision · why -->
- Seed reading sources: designed-to-scale.vercel.app and saadho.arushk.tech, 30 days each.
- CP lists are imported from pasted problem lists or URLs (no scraping dependency); solved status verified through the Codeforces public API.
- "Today's reading quota" is computed on read, not stored, so missed days redistribute automatically.
- C11 · saadho seed = its 141 `/topics/*` pages only · the rest are app/company pages, not reading
- C11 · failed extraction falls back to adding the link as a single page · matches build.md "no section list → single item"
- C10 · extractor merges HTML links (order+titles) with sitemap-only pages · sitemap alone loses titles and course order
- C10 · designed-to-scale.vercel.app is a client-rendered SPA with `#/module/n` routes, so extraction finds nothing; its 40 lessons are bundled as seed data in C11 · no headless browser dependency
- C10 · live-network tests run only with `LIVE_NETWORK=1` · keeps the gate offline-safe
- C08 · quota uses remaining-at-start-of-day (todo + done today) · otherwise ticking a page would shrink today's list
- C08 · carried-over = items an even pace (total×elapsed/target) expected done before today · simple, explainable
- C06 · Google provider refresh token is not persisted yet · token storage table lands with gcal in C24 (additive migration)
- C05 · `Db` is a small typed table repository (list/get/insert/update/remove, equality filters) · single-user scale lets domain code filter in memory; keeps both adapters trivial
- C05 · `profiles` has `id` pk + unique `user_id` · uniform repository API
- C05 · added `daily_notes`, `done_at` columns, `hackathon_milestones.gcal_event_id` · needed by C24/C28 and completion summaries
- C05 · demo store is in-memory on globalThis (resets on server restart) · simplest; no file writes on serverless
- C01 · app lives at repo root, not a `daybook/` subfolder · planning docs already at root; single package simpler
- C02 · light `--muted` #6e5e4c and `--accent` #b45309 (vs spec #7a6a58/#d97706) · spec values fail AA contrast on cream
- C02 · theme via inline pre-paint script + cookie, not server cookies() · keeps routes static, still no flash
- C02 · `scripts/smoke.mjs` headless check of routes in both themes at 375/1280px · used as the UI gate
- C01 · pnpm pinned with project `mise.toml` · no global pnpm on machine

## Blockers
<!-- Agent: exact error, what was tried, what the user must do. -->
- none

## Backlog (discovered work, not in plan)
- none

## Lighthouse scores (C32)
- Performance: –  Accessibility: –  PWA: –

## Log
<!-- newest at bottom -->
- 2026-11-21 · C01 · 05f03ad · Next 15.5 + Tailwind 4 + Vitest scaffold; gate green
- 2026-11-21 · C02 · 7e0b0cc · tokens + cookie theme with pre-paint script; smoke ok both themes
- 2026-11-21 · C03 · af82807 · 11 primitives + /dev/ui gallery; smoke ok
- 2026-11-21 · C04 · d2125e7 · rail + bottom tabs, 5 stub routes, / redirects to /today; smoke ok 375/1280
- 2026-11-21 · C05 · 59d7456 · generic typed Db interface; demo + supabase adapters; migration verified on PGlite incl. RLS
- 2026-11-21 · C06 · 8e266ef · Google OAuth w/ calendar scope + offline; middleware redirect tested; demo banner
- 2026-11-21 · C07 · 89f95a6 · todayLocal/startOfDay/daysBetween/addDays/formatDue; IST boundary tests
- 2026-11-21 · C08 · b85195f · todayQuota/todaysItems/carry-over/time split; 13 tests
- 2026-11-21 · C09 · fc9c886 · lib/db/reading + zod-validated server actions; ActionResult helper
- 2026-11-21 · C10 · b0d366c · extractPages w/ fixtures; live: saadho ok, designed-to-scale is a hash-routed SPA (empty)
- 2026-11-21 · C11 · 36470f1 · add sheet: extract → pick/reorder → create; seeds 40 + 141 pages at 30 days; e2e checked
- 2026-11-21 · C12 · 73d3f07 · source cards: progress, days left, optimistic ticks, 2-line notes, carried-over badge; multi-day test

## Handover (written in C33)
<!-- What works · what is mocked · env vars to set · 3 manual steps (Supabase project, Google OAuth, Vercel deploy) -->
