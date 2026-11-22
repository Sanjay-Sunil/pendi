# progress.md — Live Build Tracker (Pendi, Flutter)

Agent: update this file at the end of every commit. Status key: `[ ]` todo, `[x]` done, `[!]` blocked (add reason).
Log line format: `YYYY-MM-DD · Fxx · <short hash> · one-line note`

## Current state
- Next commit: **F36**
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
- [x] F08 feat(domain): reading quota planner
- [x] F09 feat(reading): sources and items repository
- [x] F10 feat(integrations): link extractor for course and blog pages
- [x] F11 feat(reading): add-source sheet with page picker
- [x] F12 feat(reading): reading screen and per-source progress

### Phase 2 — CP Tracker
- [x] F13 feat(domain): cp daily picker and streak
- [x] F14 feat(cp): list import and active list management
- [x] F15 feat(integrations): codeforces solved-status sync
- [x] F16 feat(cp): cp screen with daily 2, streak, and review queue

### Phase 3 — Work Hub
- [x] F17 feat(hackathons): repository and list view
- [x] F18 feat(hackathons): detail view with timeline and checklist
- [x] F19 feat(research): projects, daily log, and task inbox
- [x] F20 feat(research): papers, ideas, and experiments
- [x] F21 feat(research): weekly summary generator

### Phase 4 — College
- [x] F22 feat(college): courses, attendance, and skip calculator
- [x] F23 feat(college): tasks for assignments, exams, and clubs
- [x] F24 feat(gcal): calendar sync read and write

### Phase 5 — Glue
- [x] F25 feat(today): unified today screen
- [x] F26 feat(capture): quick capture sheet and inbox
- [x] F27 feat(habits): simple habits with streaks
- [x] F28 feat(notes): evening review

### Phase 6 — Polish and Ship
- [x] F29 feat(app): launcher icons, splash, and offline cache
- [x] F30 feat(settings): profile, timezone, codeforces handle, data export
- [x] F31 test(e2e): smoke flows
- [x] F32 chore: a11y, performance, and empty-state pass
- [x] F33 docs: README, setup guide, and handover

### Phase 7 — Polish and IIIT Kottayam portals
- [x] F34 style: today and shell polish
- [x] F35 feat(portals): secure college credentials and attendance client
- [ ] F36 feat(college): sync attendance into courses (80% rule)
- [ ] F37 feat(portals): moodle deadlines into college tasks
- [ ] F38 feat(college): timetable from attendance sessions

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
- F11 · link extraction runs on Android (no CORS); in the web build most sites block cross-origin fetches, so it falls back to adding the link as one page · web build is for checks only
- F17/F25 · `work` and `today` are composition screens and may import other features' providers/widgets; all other features stay independent · they exist to combine modules
- F24 · Calendar providers live in `lib/data/gcal_providers.dart` · shared by college and hackathons without cross-feature imports
- F26 · `l:` capture adds the link as a one-page reading source due in 3 days; `c:` creates an `other` college task · fastest path; details editable later. `capture` is a composition feature like today/work
- F31 · `r:` captures default to due 23:59 today so they show on Today · capture means "do today"; editable later
- F31 · integration tests run in Chrome via `flutter drive` + chromedriver (no Android emulator installed) · `tool/e2e.sh`
- 2026-11-21 · Supabase project `pendi` (ref nqnwlspndyutndhtdxwy, ap-south-1, org Sanjay-Sunil) created with the CLI; 0001 pushed; 22/22 tables RLS-on; `env.json` and `supabase/.db-password` written locally and git-ignored
- 2026-11-22 · College data comes from IIIT Kottayam portals via Pendi's own client (option A), credentials only in on-device secure storage · works without a laptop; no third-party server; AGPL code not copied
- Brand: Geist SemiBold "pendi" wordmark with an amber i-dot; icon = "p" + amber dot (`assets/brand/`, generator `tool/make_logo.py`)

## Blockers
<!-- Agent: exact error, what was tried, what the user must do. -->
- none

## Backlog (discovered work, not in plan)
- none

## Performance and accessibility (F32)
- Guideline tests: pass — 48px tap targets, labelled tap targets, AA text contrast on Today, Reading, CP, Work (both tabs), College, Inbox, Settings, in dark and light (`test/a11y/`); no overflow at 375 and 1280.
- Today in demo mode: first settle 1.5 s in the widget-test VM (includes seeding 181 pages + startup); one parallel `Future.wait` fetch, no waterfall.
- Web release: main.dart.js 3.9 MB + 2 deferred parts (Settings, UI gallery).
- On device (Samsung M52, Android 13, release APK, real Supabase in ap-south-1): first frame 0.6 s warm / 2.2 s cold; Today fully loaded from Supabase ~2.3–3.3 s (network-bound). The last saved Today is shown while it loads, and Calendar syncs in the background.

## Device test (2026-11-22)
Tested on a Samsung M52 against the real backend: Google sign-in, Calendar write + read-back, habits, capture, reading (live extraction found 361 pages), CP import/solve, hackathon template (4 Calendar events), research log autosave, export share sheet, restart persistence. Fixed: Google Sign-In not initialized after restart, Calendar errors swallowed, refresh not re-syncing Calendar, missing INTERNET permission, CP picks not refreshing after import / unstable order, page picker button buried under 361 rows, card semantics merged for screen readers.
Test data left in your account: college task "Pendi calendar test", hackathon "HackNITC" (4 milestones → 4 Google Calendar events), list "Warmups", habit "Workout", reading source saadho (3 pages), research task + log entry.

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
- 2026-11-21 · F08 · 27d567d · planner.dart ported test-for-test
- 2026-11-21 · F09 · 9ce7e2d · models w/ JSON readers; ReadingRepo with validation + Result; tests on DemoDb
- 2026-11-21 · F10 · a854b72 · html/xml parsers, injectable http client, typed errors, 8s timeout; fixtures + opt-in live test (both pass)
- 2026-11-21 · F11 · 94ad4ec · sheet: find → pick/reorder → create; fallback to single page; seeds 40 + 141 pages at 30 days; widget tests
- 2026-11-21 · F12 · 1ff4098 · cards: progress, days left, optimistic ticks w/ rollback, 2-line notes, carried-over badge, archive; multi-day provider test; a11y
- 2026-11-21 · F13 · e147c80 · pickDaily (idempotent, review first), canonicalKey, generic streak + countByDay
- 2026-11-21 · F14 · 4ccfd79 · parser for CF URLs/CSV/joined ids/JSON with per-line errors; CpRepo; lists UI (import/rename/activate); 20-problem bundled sample
- 2026-11-21 · F15 · 27bf96c · hand-validated user.status parsing, 10-min cache, typed errors; ProfileRepo for handle; CpSync notifier; fixture tests
- 2026-11-21 · F16 · 33c905b · persisted daily picks, solved/stuck/skip optimistic, notes, handle + sync button, streak flame, review queue; tests
- 2026-11-21 · F17 · 967461f · HackathonRepo CRUD; list sorted by nearest open deadline with countdown + milestone progress; Work tab segments
- 2026-11-21 · F18 · 7b4d715 · timeline + tasks w/ date pickers, overdue amber, progress %, status buttons, team/notes, Standard hackathon template; debug APK builds (phase 2 end)
- 2026-11-21 · F19 · b81ed2b · seeded NITC project; debounced autosave log (1/day) + history; Sir's tasks quick-add via enter, overdue first, priority, status
- 2026-11-21 · F20 · ff37552 · paper statuses + summaries, idea parking lot, experiment log; one search box filters all three tabs
- 2026-11-21 · F21 · ad5abff · pure weeklySummary → markdown (exact-string test); sheet with Copy (clipboard tested) and Share
- 2026-11-21 · F22 · 288f1c5 · integer-math canSkip (0 classes, exact threshold, 0/100%); course CRUD + attended/missed counters; advice text
- 2026-11-21 · F23 · 331443b · college task CRUD, kind chips filter, due-soon ordering, exam countdown cards, course link
- 2026-11-21 · F24 · ed3667f · CalendarClient interface (Google + fake w/ demo day); idempotent cache sync; dated college tasks + milestones mirrored once then updated
- 2026-11-21 · F25 · 62b2e2c · greeting + date, calendar strip, reading, CP, work top 3, college due soon, inbox count; one parallel fetch; optimistic rows w/ rollback; tap target 48
- 2026-11-21 · F26 · 472583e · FAB on every tab → sheet (2 taps: + then send); r:/c:/l: prefixes; inbox triage screen (done / to research / to college)
- 2026-11-21 · F27 · c5c86e0 · habits CRUD + idempotent day logs, weekly dots, shared streak fn; one-tap optimistic toggle on Today; fixed stale-rebuild reset in optimistic rows
- 2026-11-21 · F28 · bcfa124 · day summary counted from real completion timestamps; one-line reflection (optionally appended to research log); tomorrow's top 3 shown on next day's Today
- 2026-11-21 · F29 · c978407 · adaptive + legacy Android icons, Android 12 splash + launch layer, web icons/manifest/theme-color; Today snapshot cached in prefs and shown offline with a banner
- 2026-11-21 · F30 · acc6fe7 · settings from Today header: theme, timezone (runtime activeTimezone), CF handle, sign out; JSON export validated against every table model before sharing
- 2026-11-21 · F31 · b7db94a · integration_test in demo mode: add source + complete page, CP solved, r: capture shows on Today; tool/e2e.sh (chromedriver, headless) passes
- 2026-11-21 · F32 · 0d39936 · guideline tests on every main screen x2 themes; wide-layout overflow check; research tasks empty state; deferred Settings/gallery; perf numbers recorded
- 2026-11-21 · F33 · 4026c07 · README (≤10-line run), docs/SETUP.md (Supabase, Google OAuth incl. SHA-1, release APK, env table), handover in progress.md
- 2026-11-21 · F34 · 3047907 · day-progress header, sectioned cards w/ icons + counts, equal-height calendar cards w/ time ranges, fade-in, soft-tint chips/segments, inbox row; checked on device in dark + light
- 2026-11-21 · F35 · fc19d89 · own Dart client for attendance.iiitkottayam.ac.in (login + attendance, tolerant parsing, typed errors); login in Android Keystore; Settings → College account; device check pending your login

## Handover (written in F33)

**What works (demo mode, verified by 162 unit/widget tests + 3 Chrome smoke flows):**
- Today: greeting, calendar strip, reading pages, CP daily 2 + streak, work top 3 (hackathon + research), college due soon, habits with streaks, inbox count, yesterday's top 3, evening review. Rows complete in place (optimistic, roll back on error). Offline: last Today is cached and shown with a banner.
- Reading: add a link → pick/reorder pages → daily quota that redistributes missed days, carry-over badges, notes, archive. Seeded with Designed to Scale (40) and Saadho (141) at 30 days.
- CP: import lists (CF URLs, CSV, `1950B`, JSON) with per-line errors, active list, persisted daily picks, solved/stuck/skip, notes, review queue, Codeforces sync (cached 10 min).
- Work: hackathons (deadline sort, countdowns, timeline, template, tasks, team/notes, status); research (tasks with priority and overdue-first, autosaving daily log + history, papers/ideas/experiments with one search box, weekly Markdown summary with copy/share).
- College: courses with attendance and skip calculator, tasks by kind with exam countdowns.
- Quick capture from every tab (`r:` / `c:` / `l:`), inbox triage, settings (theme, timezone, CF handle, JSON export validated against every table model), Android icons + splash.

**What is mocked or limited:**
- Demo mode: data is in memory and resets on restart; Calendar uses a fake sample day.
- Google sign-in, Supabase sync and real Calendar read/write are implemented but untested against live services (no keys in this environment).
- Link extraction is blocked by CORS in the web build (falls back to one page); it works on Android.
- Not run here: the app on a physical Android phone/emulator, and a profile-mode Today timing (no device available). The debug APK builds.

**Env vars to set (`env.json`):** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`, optional `APP_TIMEZONE`. See `docs/SETUP.md`.

**3 manual steps:**
1. ~~Supabase project~~ Done: project `pendi` exists, migration applied, `env.json` filled with URL + publishable key (local only).
2. Google OAuth client IDs: Web and Android (debug SHA-1) clients created 2026-11-22; IDs in `supabase/.env.local` (git-ignored). Remaining: enable the Google provider in the Supabase dashboard with both client IDs + secret + skip nonce check. Add a second Android client for the release SHA-1 before shipping a release APK.
3. Release APK: create a keystore, wire `key.properties`, `flutter build apk --release --dart-define-from-file=env.json`.
