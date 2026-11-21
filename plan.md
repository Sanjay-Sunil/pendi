# plan.md — Ordered Commit Plan

Rules: do the commits in order. Each commit is one reviewable unit. Each leaves the gate green (`pnpm typecheck && pnpm lint && pnpm test && pnpm build`). Use the exact commit message. Full stack, schema, and tokens are in `build.md`.

Legend: **Scope** = what to do. **Done when** = acceptance criteria you must verify.

---
## Phase 0 — Foundation

### C01 `chore: bootstrap Next.js app with tooling`
- Scope: run bootstrap from `build.md`; add Prettier, Vitest config, scripts, `.env.example`, `.gitignore`, minimal `README.md`.
- Done when: gate passes on a blank app; `pnpm test` runs one sample test.

### C02 `feat(ui): design tokens, fonts, theme toggle`
- Scope: `globals.css` tokens (dark default + cream light), Geist fonts, theme provider + cookie, `ThemeToggle`.
- Done when: toggle switches themes without flash on reload; amber accent visible on a demo button.

### C03 `feat(ui): core primitives`
- Scope: Button, Card, Input, Textarea, Checkbox, Badge, ProgressBar, Tabs, Sheet, EmptyState, SectionLabel in `src/components/ui`. Add a hidden `/dev/ui` gallery route.
- Done when: gallery shows every primitive in both themes; keyboard focus rings visible.

### C04 `feat(shell): app layout with rail and mobile tab bar`
- Scope: `(app)/layout.tsx`, desktop left rail, mobile bottom tabs (Today, Reading, CP, Work, College), stub pages, active-route amber indicator, safe-area padding.
- Done when: all five routes render stubs; layout correct at 375px and 1280px.

### C05 `feat(data): supabase clients, demo-mode adapter, and migration 0001`
- Scope: `supabase/migrations/0001_init.sql` per `build.md` with RLS; `src/lib/supabase/*`; `src/lib/db` interface with a demo (in-memory + seed) adapter selected when env keys are absent.
- Done when: app runs with no env vars (demo mode); migration SQL lints; a unit test covers the demo adapter CRUD.

### C06 `feat(auth): google sign-in and route protection`
- Scope: `/login`, Supabase OAuth with Google + calendar scope, middleware protecting `(app)`; demo mode bypasses auth with a banner.
- Done when: unauthenticated users are redirected (when keys are set); demo mode loads Today directly.

### C07 `feat(domain): date utilities with timezone tests`
- Scope: `src/lib/domain/dates.ts` (`todayLocal`, `startOfDay`, `daysBetween`, `formatDue`) using `APP_TIMEZONE`.
- Done when: tests cover IST midnight boundaries and DST-free zones.

---
## Phase 1 — Reading Planner

### C08 `feat(domain): reading quota planner`
- Scope: `planner.ts` per `build.md` (`todayQuota`, `todaysItems`, carry-over, time-based splitting).
- Done when: unit tests cover: even split, missed days redistribute, last day takes all remaining, completed source returns 0.

### C09 `feat(reading): sources and items data layer with actions`
- Scope: db functions + server actions: create source, add items, toggle item, archive source. Zod schemas.
- Done when: tests pass against the demo adapter.

### C10 `feat(integrations): link extractor for course and blog pages`
- Scope: `sitemap.ts` server function: fetch URL, prefer sitemap.xml, else extract same-origin links in order, dedupe, return `{title,url}[]`. Timeout 8s, user agent set, errors typed.
- Done when: unit tests with fixture HTML; works against both seed URLs when network is available, else skipped with a clear message.

### C11 `feat(reading): add-source flow with page picker`
- Scope: Reading page: "Add" sheet taking a link + number of days; shows extracted pages as a checklist (select only required pages, select-all, reorder-lite); creates source and items. Seed both default sources at 30 days.
- Done when: adding a link produces items; unselected pages are excluded; quota shown ("4 pages today").

### C12 `feat(reading): reading screen and per-source progress`
- Scope: list sources with progress bar, days left, today's pages as tappable tasks that open the URL and can be checked, optional 2-line note on completion, carried-over badge.
- Done when: completing items updates progress and tomorrow's quota correctly (test with mocked date).

---
## Phase 2 — CP Tracker

### C13 `feat(domain): cp daily picker and streak`
- Scope: `cp.ts` with `pickDaily`, `streak`, `canonicalKey`. Idempotent.
- Done when: tests cover idempotency, review-queue priority, streak across gaps.

### C14 `feat(cp): list import and active list management`
- Scope: import problems via pasted CSV/JSON/CF URLs; create, rename, activate lists; bundled sample list.
- Done when: pasted URLs parse into `(contestId, idx)`; invalid lines reported, not fatal.

### C15 `feat(integrations): codeforces solved-status sync`
- Scope: `codeforces.ts` with Zod-validated API response, 10-min cache, handle stored in settings; sync action marks problems solved.
- Done when: unit tests with recorded fixture; failure path shows a toast, never crashes.

### C16 `feat(cp): cp screen with daily 2, streak, and review queue`
- Scope: Today's 2 problems with open-in-Codeforces links, manual mark solved/stuck→review/skip, per-problem note, "Sync from Codeforces" button, streak flame.
- Done when: marking solved updates streak; refresh keeps the same 2 problems.

---
## Phase 3 — Work Hub

### C17 `feat(hackathons): data layer and list view`
- Scope: CRUD for hackathons, milestones, tasks; list with next-deadline countdown and status.
- Done when: can add multiple hackathons; sorted by nearest deadline.

### C18 `feat(hackathons): detail view with timeline and checklist`
- Scope: per-hackathon page: milestone timeline (registration → rounds → submission), task checklist, links, team, notes. Template button "Standard hackathon" that pre-fills milestones.
- Done when: completing milestones updates the progress indicator; overdue items highlighted amber.

### C19 `feat(research): projects, daily log, and task inbox`
- Scope: research project (seed "NITC research internship"), daily log editor (autosave, one entry per day, history list), "Sir's tasks" inbox with due date, priority, status (todo/doing/done), and quick-add.
- Done when: log autosaves; tasks can be added in under 3 taps; overdue first.

### C20 `feat(research): papers, ideas, and experiments`
- Scope: reading list for papers (to_read/reading/done + summary), idea parking lot, experiment log (hypothesis, result), all searchable in one filter box.
- Done when: items move between statuses; search filters across tabs.

### C21 `feat(research): weekly summary generator`
- Scope: button that compiles the week's logs, completed tasks, papers read, and experiments into copyable markdown (pure function + test).
- Done when: output snapshot test passes; copy-to-clipboard works.

---
## Phase 4 — College

### C22 `feat(college): courses, attendance, and skip calculator`
- Scope: course CRUD, attended/total counters, `canSkip` calculator with clear messaging, tests.
- Done when: counters update; calculator correct on edge cases (0 classes, exactly at threshold).

### C23 `feat(college): tasks for assignments, exams, and clubs`
- Scope: college_tasks CRUD with kind filter, due dates, exam countdown cards.
- Done when: filters work; due-soon ordering correct.

### C24 `feat(gcal): calendar sync read and write`
- Scope: `gcal.ts` reads events into cache, `/api/gcal/sync` route; writing a task/milestone with a due date creates/updates an event and stores `gcal_event_id`. Mockable client; demo mode shows sample events.
- Done when: tests with a mocked client; sync is idempotent (no duplicate events).

---
## Phase 5 — Glue

### C25 `feat(today): unified today screen`
- Scope: `today` module composing calendar strip, reading, CP, work (top 3 due/overdue), college due soon, habits, inbox count. Optimistic checkboxes. Greeting + date in mono label.
- Done when: all sections render in demo mode; completing a row updates in place; single batched query.

### C26 `feat(capture): quick capture palette and inbox`
- Scope: global `⌘K` / floating "+" button using cmdk: capture a note to inbox, or create a research task / college task / reading link with prefix commands (`r:` research task, `c:` college task, `l:` link). Inbox triage screen.
- Done when: capture works from every page in under 2 taps on mobile.

### C27 `feat(habits): simple habits with streaks`
- Scope: habits CRUD, one-tap daily log on Today, weekly dots, streak using the pure streak function.
- Done when: streak tests pass; toggling is optimistic.

### C28 `feat(notes): evening review`
- Scope: Evening check-in sheet: what got done (auto-summary), one-line reflection saved to research log or a general daily note, tomorrow's top 3 picks.
- Done when: summary counts match actual completions.

---
## Phase 6 — Polish and Ship

### C29 `feat(pwa): manifest, icons, offline shell`
- Scope: `manifest.webmanifest`, amber monogram icons (192, 512, maskable), minimal service worker caching the shell, theme-color meta per theme.
- Done when: installable in Chrome devtools; offline shows cached shell with a friendly message.

### C30 `feat(settings): profile, timezone, codeforces handle, data export`
- Scope: settings page; JSON export of all user data; theme control.
- Done when: export downloads valid JSON that re-validates against Zod schemas.

### C31 `test(e2e): smoke flows`
- Scope: Playwright in demo mode: (1) add reading source and complete a page, (2) mark a CP problem solved, (3) quick-capture a research task and see it on Today.
- Done when: `pnpm e2e` passes locally.

### C32 `chore: a11y, performance, and empty-state pass`
- Scope: audit focus order, labels, contrast; add empty states everywhere; lazy-load non-critical sheets; run Lighthouse on `/today`.
- Done when: Lighthouse mobile ≥ 90 on Performance, Accessibility, and PWA (record scores in `progress.md`).

### C33 `docs: README, deploy guide, and handover`
- Scope: README with 10-line setup, Supabase and Google OAuth steps, Vercel deploy, env var table, cron setup for `/api/cron/gcal` and `/api/cron/cp-sync` (Vercel cron, protected by `CRON_SECRET`). Write the Handover section in `progress.md`.
- Done when: a fresh clone can run in demo mode with only `pnpm i && pnpm dev`.

---
## After v1 (do NOT build unless all above are `[x]`)
Attendance reminders, expense split, Pomodoro timer, weekly stats page, push notifications. Add to the Backlog in `progress.md` only.
