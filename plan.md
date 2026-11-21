# plan.md — Ordered Commit Plan (Flutter)

Rules: do the commits in order. Each commit is one reviewable unit. Each leaves the gate green (see `agent.md`). Use the exact commit message. Full stack, schema, tokens and brand are in `build.md`.

Legend: **Scope** = what to do. **Done when** = acceptance criteria you must verify.

Carried over from the earlier Next.js build (kept on branch `nextjs-web`, reuse freely): `supabase/migrations/0001_init.sql` (verified, with RLS), the seed snapshots, design tokens, `assets/brand/` + `assets/fonts/`, and the tested TypeScript domain logic (`src/lib/domain/*`, `src/lib/integrations/sitemap-parse.ts`) to port to Dart test-for-test.

---
## Phase 0 — Foundation

### F01 `chore: replace Next.js scaffold with Flutter app`
- Scope: remove the Next.js files from `main` (they stay on `nextjs-web`); run the bootstrap from `build.md` at the repo root; strict `analysis_options.yaml`; `env.example.json`, `.gitignore` (`env.json`, build outputs); move seed JSON to `assets/seed/`; register fonts and assets in `pubspec.yaml`; minimal `README.md`; one sample unit test.
- Done when: gate passes on the blank app; `flutter run -d chrome` shows a placeholder "pendi" screen.

### F02 `feat(ui): design tokens, fonts, theme mode`
- Scope: `PendiColors` `ThemeExtension` from the tokens, light + dark `ThemeData`, Geist/Geist Mono from assets, theme mode provider persisted with `shared_preferences` (system → dark/light), toggle button.
- Done when: toggling switches themes instantly and survives restart; widget test asserts both palettes resolve.

### F03 `feat(ui): core primitives`
- Scope: AppButton (primary/secondary/ghost/danger), AppCard, AppInput, AppTextArea, AppCheckbox, AppBadge, AppProgressBar, AppTabs, AppSheet (modal bottom sheet), EmptyState, SectionLabel in `lib/ui/`. Hidden `/dev/ui` gallery route.
- Done when: gallery shows every primitive in both themes; widget tests pass tap-target, labeled-tap-target and contrast guidelines on the gallery.

### F04 `feat(shell): tab scaffold with rail and bottom bar`
- Scope: `go_router` `StatefulShellRoute` with five branches (Today, Reading, CP, Work, College), bottom navigation bar under 600dp width and a slim `NavigationRail` above, amber active indicator, safe areas, stub screens, wordmark in the rail.
- Done when: all five tabs render stubs and keep their state when switching; widget tests at 375 and 1280 logical px.

### F05 `feat(data): db interface, demo adapter, supabase adapter`
- Scope: `lib/data/db.dart`, `DemoDb` (defaults, unique constraints, cascades, copies) seeded with the profile, `SupabaseDb`, `dbProvider` choosing demo when env is empty, `Result` type and `DbConflict`/`DbNotFound` errors. Keep `0001_init.sql` unchanged.
- Done when: app runs with no env (demo mode); unit tests cover DemoDb CRUD, uniques, cascades.

### F06 `feat(auth): google sign-in and auth gate`
- Scope: login screen with the wordmark; `google_sign_in` with Calendar scope → `supabase.auth.signInWithIdToken`; router redirect to `/login` when signed out; sign-out; demo mode skips auth and shows a "Demo mode" strip.
- Done when: with keys set, a signed-out user lands on `/login` (widget test with a fake auth repo); demo mode opens Today directly.

### F07 `feat(domain): date utilities with timezone tests`
- Scope: port `dates.ts` to `lib/domain/dates.dart` using the `timezone` package; initialise tz data in `main`.
- Done when: the same cases as the TS suite pass (IST midnight boundaries, DST-free zones, leap year, formatDue labels).

---
## Phase 1 — Reading Planner

### F08 `feat(domain): reading quota planner`
- Scope: port `planner.ts` (`todayQuota`, `todaysItems` with fixed-at-start-of-day quota and carry-over, `splitByReadingTime`, `estimateMinutes`).
- Done when: ported tests pass: even split, missed days redistribute, last day takes all, completed source returns 0, stable list while ticking, carry-over flags.

### F09 `feat(reading): sources and items repository`
- Scope: models + `ReadingRepo`: create source with pages, add items (append, dedupe by URL), set done/undone with timestamp and note, set note, archive. Input validation returning `Result`.
- Done when: tests pass against `DemoDb`.

### F10 `feat(integrations): link extractor for course and blog pages`
- Scope: `sitemap.dart` with the `html` and `xml` packages: same-origin links under the base path in document order, sitemap-only pages appended, dedupe, 8s timeout, user agent, typed errors. Injectable `http.Client`.
- Done when: fixture tests pass (reuse the HTML/XML fixtures from `nextjs-web`); live test against saadho runs only with `--dart-define=LIVE_NETWORK=true`.

### F11 `feat(reading): add-source sheet with page picker`
- Scope: Reading screen "Add" opens a sheet: link + days (+ optional title) → "Find pages" → checklist with select-all and up/down reorder → create. Extraction failure falls back to a single page. Seed both default sources at 30 days from `assets/seed/`.
- Done when: adding a link produces items; unselected pages are excluded; each source shows "N pages today" (widget test with a fake extractor).

### F12 `feat(reading): reading screen and per-source progress`
- Scope: source cards with progress bar, "x/y read · n days left", today's pages as rows that open the URL (`url_launcher`) and can be ticked (optimistic), optional 2-line note after ticking, carried-over badge, archive.
- Done when: completing items updates progress and tomorrow's quota correctly (repo + provider test with a fixed clock).

---
## Phase 2 — CP Tracker

### F13 `feat(domain): cp daily picker and streak`
- Scope: `cp.dart` (`pickDaily`, `canonicalKey`) and `streak.dart` (generic over days with completions, threshold N).
- Done when: tests cover idempotency, review-queue priority, streak across gaps, today-or-yesterday rule.

### F14 `feat(cp): list import and active list management`
- Scope: import via pasted CSV/JSON/Codeforces URLs (`/contest/1950/problem/B`, `/problemset/problem/1950/B`); create, rename, activate lists; bundled sample list.
- Done when: pasted URLs parse into `(contestId, index)`; invalid lines are reported, not fatal.

### F15 `feat(integrations): codeforces solved-status sync`
- Scope: `codeforces.dart` with hand-validated JSON, 10-minute cache, handle from profile; sync marks problems solved.
- Done when: unit tests with a recorded fixture; failure shows a snackbar, never crashes.

### F16 `feat(cp): cp screen with daily 2, streak, and review queue`
- Scope: today's 2 problems with open-in-Codeforces, mark solved / stuck → review / skip, per-problem note, "Sync from Codeforces", streak flame.
- Done when: marking solved updates the streak; reopening the screen keeps the same 2 problems.

---
## Phase 3 — Work Hub

### F17 `feat(hackathons): repository and list view`
- Scope: CRUD for hackathons, milestones, tasks; list with next-deadline countdown and status. Work tab hosts Hackathons and Research as segments.
- Done when: multiple hackathons sort by nearest deadline.

### F18 `feat(hackathons): detail view with timeline and checklist`
- Scope: milestone timeline (registration → rounds → submission), task checklist, links, team, notes; "Standard hackathon" template.
- Done when: completing milestones updates progress; overdue items highlighted amber.

### F19 `feat(research): projects, daily log, and task inbox`
- Scope: seed "NITC research internship"; daily log editor (debounced autosave, one entry per day, history); "Sir's tasks" with due date, priority, status, quick-add.
- Done when: log autosaves; a task can be added in ≤ 3 taps; overdue first.

### F20 `feat(research): papers, ideas, and experiments`
- Scope: paper reading list (to_read/reading/done + summary), idea parking lot, experiment log; one search box filtering all tabs.
- Done when: items move between statuses; search filters across tabs.

### F21 `feat(research): weekly summary generator`
- Scope: pure `weekly_summary.dart` compiling the week's logs, done tasks, papers read, experiments into Markdown; copy and share buttons.
- Done when: golden-string test passes; copy puts the text on the clipboard.

---
## Phase 4 — College

### F22 `feat(college): courses, attendance, and skip calculator`
- Scope: course CRUD, +attended / +missed counters, `canSkip` with clear messaging.
- Done when: counters update; calculator correct on edge cases (0 classes, exactly at threshold).

### F23 `feat(college): tasks for assignments, exams, and clubs`
- Scope: college task CRUD with kind filter, due dates, exam countdown cards.
- Done when: filters work; due-soon ordering correct.

### F24 `feat(gcal): calendar sync read and write`
- Scope: `gcal.dart` behind an interface; read events into `gcal_events_cache`; writing a task/milestone with a due date creates/updates an event and stores `gcal_event_id`; demo mode shows sample events.
- Done when: tests with a fake client; sync is idempotent (no duplicate events).

---
## Phase 5 — Glue

### F25 `feat(today): unified today screen`
- Scope: greeting + date mono label, calendar strip, Reading, CP, Work top 3, College due soon, Habits, Inbox count; optimistic checkboxes; one parallel fetch.
- Done when: all sections render in demo mode; completing a row updates in place.

### F26 `feat(capture): quick capture sheet and inbox`
- Scope: floating "+" on every tab opens a capture sheet: plain text → inbox; prefixes `r:` research task, `c:` college task, `l:` reading link. Inbox triage screen.
- Done when: capture works from every tab in ≤ 2 taps.

### F27 `feat(habits): simple habits with streaks`
- Scope: habits CRUD, one-tap log on Today, weekly dots, streak from `streak.dart`.
- Done when: streak tests pass; toggling is optimistic.

### F28 `feat(notes): evening review`
- Scope: evening check-in sheet: auto-summary of the day's completions, one-line reflection (to research log or `daily_notes`), tomorrow's top 3.
- Done when: summary counts match actual completions (test).

---
## Phase 6 — Polish and Ship

### F29 `feat(app): launcher icons, splash, and offline cache`
- Scope: Android adaptive icon from `assets/brand/pendi-icon-foreground.png` on `#0C0A09`, web icons/manifest, native splash in theme colours, last-loaded Today cached locally so the app opens offline with a friendly banner.
- Done when: icon and splash show on an emulator/device build; airplane mode shows cached Today.

### F30 `feat(settings): profile, timezone, codeforces handle, data export`
- Scope: settings screen (theme, timezone, CF handle, sign out); export all user data as JSON via the share sheet.
- Done when: exported JSON round-trips through the model `fromJson` for every table (test).

### F31 `test(e2e): smoke flows`
- Scope: `integration_test` in demo mode: (1) add a reading source and complete a page, (2) mark a CP problem solved, (3) quick-capture a research task and see it on Today.
- Done when: `flutter test integration_test` passes on Chrome or an emulator.

### F32 `chore: a11y, performance, and empty-state pass`
- Scope: semantics labels, focus order, contrast; empty states everywhere; deferred loading of heavy sheets; profile-mode check of Today.
- Done when: accessibility guideline tests pass on every main screen; Today first frame < 1s in profile mode (record numbers in `progress.md`).

### F33 `docs: README, setup guide, and handover`
- Scope: README with ≤ 10-line setup, Supabase project + migration steps, Google OAuth (Android SHA-1, web client ID), release APK build, env table. Write the Handover section in `progress.md`.
- Done when: a fresh clone runs in demo mode with only `flutter pub get && flutter run`.

---
## After v1 (do NOT build unless all above are `[x]`)
Attendance reminders, local notifications, home-screen widget, expense split, Pomodoro timer, weekly stats page, background Calendar/Codeforces sync. Add to the Backlog in `progress.md` only.
