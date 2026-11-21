# build.md — Stack, Setup, Schema, Design Tokens

## Product in one paragraph
Daybook is a mobile-first PWA with one **Today** screen that merges four engines: Reading Planner, CP Tracker, Work Hub (hackathons + research internship), and College (Google Calendar, classes, club tasks). Single user, private, fast.

## Stack
- Next.js 15 (App Router) + TypeScript strict + Tailwind CSS v4
- Supabase: Postgres, Auth (Google OAuth, also used for Calendar scope), Row Level Security
- Zod, date-fns + date-fns-tz, lucide-react, sonner (toasts), cmdk (quick capture palette)
- Vitest (unit), Playwright (smoke), pnpm
- Deploy: Vercel. PWA via `manifest.webmanifest` + a minimal service worker (cache shell only).
- No component library. Build small primitives in `src/components/ui` (Button, Card, Input, Checkbox, Badge, Sheet, Tabs, ProgressBar, EmptyState).

## Bootstrap commands
```
pnpm create next-app@latest daybook --ts --tailwind --app --src-dir --eslint --import-alias "@/*" --use-pnpm
cd daybook
pnpm add @supabase/supabase-js @supabase/ssr zod date-fns date-fns-tz lucide-react sonner cmdk
pnpm add -D vitest @vitest/coverage-v8 @playwright/test prettier
```
Scripts in `package.json`: `dev`, `build`, `lint`, `typecheck` (`tsc --noEmit`), `test` (`vitest run`), `e2e` (`playwright test`).

## Environment (`.env.example`)
```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=        # server only, used by cron/sync routes
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APP_TIMEZONE=Asia/Kolkata
CRON_SECRET=                      # protects /api/cron/*
```
If keys are missing, run in **demo mode**: `src/lib/db` falls back to an in-memory/local JSON store behind the same interface so the whole UI is buildable and testable with no backend.

## Folder structure
```
src/
  app/
    (auth)/login/
    (app)/layout.tsx            # shell: rail + bottom tabs
    (app)/today/ reading/ cp/ work/ college/ notes/ settings/
    api/cron/ api/gcal/
  components/ui/   components/shell/
  lib/
    db/            # all data access (supabase + demo adapter)
    domain/        # pure logic + tests: planner.ts streak.ts dates.ts cp.ts
    integrations/  # codeforces.ts gcal.ts sitemap.ts
    supabase/      # server/client helpers
  modules/
    reading/ cp/ hackathons/ research/ college/ today/ capture/
supabase/migrations/
tests/ e2e/
```

## Database schema (migration `0001_init.sql`)
All tables have `id uuid pk default gen_random_uuid()`, `user_id uuid not null references auth.users`, `created_at timestamptz default now()`. Enable RLS on every table with policy `user_id = auth.uid()` for all operations.

```
profiles(user_id pk, timezone text default 'Asia/Kolkata', cf_handle text, gcal_calendar_id text)

-- Reading
reading_sources(title, url, kind text check in ('course','blog'), start_date date, target_days int, status text default 'active')
reading_items(source_id fk, title, url, position int, status text default 'todo' check in ('todo','done','skipped'), done_at timestamptz, note text)
  -- unique(source_id, url)

-- CP
cp_lists(name, source text, active bool default false)
cp_problems(list_id fk, contest_id int, idx text, name, rating int, position int, status text default 'todo' check in ('todo','solved','review','skipped'), solved_at timestamptz, note text)
cp_daily(day date, problem_id fk, unique(day, problem_id))

-- Work Hub: hackathons
hackathons(name, url, status text default 'active', theme text, team text, notes text)
hackathon_milestones(hackathon_id fk, title, due_at timestamptz, done bool default false, kind text)  -- registration, round, submission...
hackathon_tasks(hackathon_id fk, title, due_at, done bool default false)

-- Work Hub: research internship
research_projects(name, org text, mentor text, active bool default true)
research_logs(project_id fk, day date, body text)               -- daily notes
research_tasks(project_id fk, title, assigned_by text, due_at, status text default 'todo' check in ('todo','doing','done'), priority int default 2)
research_papers(project_id fk, title, url, status text default 'to_read' check in ('to_read','reading','done'), summary text)
research_ideas(project_id fk, body text, status text default 'parked')
research_experiments(project_id fk, title, hypothesis text, result text, day date)

-- College
courses(name, code, attendance_attended int default 0, attendance_total int default 0, min_pct int default 75)
college_tasks(title, course_id fk null, kind text check in ('assignment','exam','club','other'), due_at, done bool default false, gcal_event_id text)
gcal_events_cache(gcal_event_id unique, title, starts_at, ends_at, all_day bool)  -- read-only mirror

-- Cross-cutting
inbox(body text, resolved bool default false)                    -- quick capture
habits(name, target_per_week int default 7)
habit_logs(habit_id fk, day date, unique(habit_id, day))
```

## Core domain logic (pure, tested)

**Reading planner** (`planner.ts`)
- `todayQuota(remainingItems, startDate, targetDays, today)` returns `ceil(remaining / max(1, daysLeft))` where `daysLeft = targetDays - daysElapsed`. Nothing stored; recomputed on read, so missed days redistribute automatically.
- Today's reading tasks = first `quota` `todo` items by `position`, plus any item scheduled earlier but not done (these show as "carried over").
- Adding a custom blog by link: target_days given by the user. If the page has no section list, create a single item and split by estimated reading time into "Part n" items (`ceil(minutes / 20)` parts).

**Reading sources import** (`sitemap.ts`)
- Fetch the source's index page server-side, extract same-origin links in document order (prefer `sitemap.xml` if present), dedupe, and present a checklist so the user picks **only the pages required**. Seed two sources: `https://designed-to-scale.vercel.app/` and `https://saadho.arushk.tech/`, each with `target_days = 30`.

**CP daily picker** (`cp.ts`)
- `pickDaily(problems, day)`: if `cp_daily` already has rows for `day`, return them; else take the first 2 problems with status `todo` (or `review` due) in list order and persist them. Idempotent.
- Streak = consecutive days with at least 1 solved CP problem (configurable to 2) ending today or yesterday.
- Codeforces sync (`codeforces.ts`): `GET https://codeforces.com/api/user.status?handle=<h>&from=1&count=200`; mark a problem solved when a submission has `verdict == "OK"` and matches `(contestId, index)`. Cache 10 minutes. Handle API errors gracefully.
- TLE Eliminators lists: import via pasted CSV/JSON of `(contestId, index)` or Codeforces problem URLs. No scraping dependency. Provide a bundled sample list for demo mode.

**Today view** (`today` module)
Sections in order: Calendar strip (today's gcal events), Reading, CP, Work (due-today and overdue hackathon and research tasks, top 3), College (due soon), Habits, Inbox count. Each row has a checkbox that completes it in place (optimistic UI).

**Attendance** : `canSkip(attended, total, minPct)` returns how many more classes can be missed while staying at or above minPct, or how many must be attended to recover.

**Google Calendar** (`gcal.ts`)
- Google OAuth scope `https://www.googleapis.com/auth/calendar` (read+write) requested via Supabase Auth provider options, store provider tokens server-side. Read events into `gcal_events_cache` on demand and via cron. Writing a `college_task` or hackathon milestone with a due date creates or updates a Calendar event and stores `gcal_event_id`.

## Design tokens (`src/app/globals.css`)
Dark is default. Light is a warm cream theme (the reference site uses `#f4ebe0` cream). Toggle stored in a cookie; also respects `prefers-color-scheme` on first load.

```css
:root {                       /* light (cream) */
  --bg: #f4ebe0;  --surface: #fbf6ee;  --surface-2: #efe4d4;
  --border: #e0d2bd;  --text: #2a2118;  --muted: #7a6a58;
  --accent: #d97706;  --accent-fg: #ffffff;  --accent-soft: #fde9c7;
  --success: #4d7c0f;  --danger: #b42318;
}
.dark {                       /* dark (default) */
  --bg: #0c0a09;  --surface: #151311;  --surface-2: #1c1917;
  --border: #292524;  --text: #ede7df;  --muted: #8f867b;
  --accent: #f59e0b;  --accent-fg: #1a1203;  --accent-soft: #2b2007;
  --success: #84cc16;  --danger: #f87171;
}
```
- Radius: card 12px, control 8px, pill 999px. Border: 1px solid `--border`. No shadows except a 1px inner highlight on hover.
- Fonts via `next/font`: Geist Sans (UI) and Geist Mono (labels, numbers). Body 15px/1.6; section label 11px mono uppercase, letter-spacing 0.08em, `--muted`.
- Spacing scale 4/8/12/16/24/40. Page padding 20px mobile, 40px desktop. Content max-width 720px (Today), 960px (other pages).
- Components: checkbox is a 20px rounded square that fills amber with a check; progress bars are 4px tall amber on `--surface-2`; streak is a small amber flame icon with a mono number.
- Empty states: one line of muted text plus one amber ghost button. No illustrations.

## Quality bar
- Lighthouse PWA/Performance/Accessibility ≥ 90 on `/today` (mobile).
- Today renders from a single server query batch, no waterfall.
- Every mutation is a server action with Zod validation and optimistic UI.
