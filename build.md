# build.md — Stack, Setup, Schema, Design Tokens

## Product in one paragraph
Pendi is a mobile-first Flutter app with one **Today** screen that merges four engines: Reading Planner, CP Tracker, Work Hub (hackathons + research internship), and College (Google Calendar, classes, club tasks). Single user, private, fast. Android is the primary target; the same code must also build for web so it can be checked in a browser.

## Stack
- Flutter (stable, 3.47+) / Dart 3, null-safe, `very_good_analysis`-style strict lints
- State: `flutter_riverpod` (no code generation). Routing: `go_router` with a `StatefulShellRoute` for the tab bar.
- Backend: Supabase via `supabase_flutter` (Postgres, Auth, Row Level Security)
- Auth: Google Sign-In via `google_sign_in`, exchanged for a Supabase session with `signInWithIdToken`; Calendar scope requested on the same sign-in
- Google Calendar: `googleapis` (calendar/v3) + `extension_google_sign_in_as_googleapis_auth`
- HTTP + parsing: `http`, `html` (link extractor), `xml` (sitemaps)
- Dates: `timezone` package (IANA data) + `intl`
- Fonts: `google_fonts` with Geist and Geist Mono **bundled as assets** (no runtime fetching)
- Icons: `lucide_icons_flutter` (fallback: Material Symbols Rounded)
- Toasts: `ScaffoldMessenger` snackbars styled to the theme. Quick capture: a custom bottom sheet (no package).
- Sharing/export: `share_plus`, `path_provider`
- Tests: `flutter_test` (unit + widget), `integration_test` for 3 smoke flows, `mocktail` for fakes
- No code generation (`build_runner`, freezed, json_serializable). Models are hand-written immutable classes with `fromJson`/`toJson`/`copyWith`.
- No component library. Build small widgets in `lib/ui/` (AppButton, AppCard, AppInput, AppCheckbox, AppBadge, AppSheet, AppTabs, AppProgressBar, EmptyState, SectionLabel).

## Bootstrap commands
```
flutter create --org dev.pendi --project-name pendi --platforms android,web .
flutter pub add flutter_riverpod go_router supabase_flutter google_sign_in googleapis \
  extension_google_sign_in_as_googleapis_auth http html xml timezone intl google_fonts \
  lucide_icons_flutter share_plus path_provider
flutter pub add --dev mocktail very_good_analysis integration_test --sdk=flutter
```
(`integration_test` comes from the SDK: add it under `dev_dependencies` with `sdk: flutter`.)

## Configuration
No secrets in the repo. Values are passed at build time with `--dart-define-from-file=env.json` (git-ignored); `env.example.json` is committed:
```json
{
  "SUPABASE_URL": "",
  "SUPABASE_ANON_KEY": "",
  "GOOGLE_WEB_CLIENT_ID": "",
  "APP_TIMEZONE": "Asia/Kolkata"
}
```
Read through `lib/core/env.dart` (`String.fromEnvironment`). If `SUPABASE_URL` or `SUPABASE_ANON_KEY` is empty the app runs in **demo mode**: repositories use an in-memory store seeded from `assets/seed/`, auth is skipped, and a "Demo mode" strip is shown. The whole UI must be usable and testable this way.

## Folder structure
```
lib/
  main.dart                  # bootstrap: env, timezone db, Supabase (if configured), ProviderScope
  app.dart                   # MaterialApp.router, themes
  core/                      # env.dart, router.dart, result.dart, errors
  theme/                     # tokens.dart, app_theme.dart, theme_mode_provider.dart
  ui/                        # shared widgets (primitives)
  shell/                     # tab scaffold: bottom bar (mobile) / navigation rail (wide)
  data/
    db.dart                  # Db interface (table repository)
    demo_db.dart             # in-memory adapter + seed
    supabase_db.dart         # Supabase adapter
    models/                  # one file per table model
    repos/                   # reading_repo.dart, cp_repo.dart, ... (all data access)
  domain/                    # pure Dart + tests: dates.dart planner.dart cp.dart streak.dart attendance.dart weekly_summary.dart
  integrations/              # sitemap.dart codeforces.dart gcal.dart
  features/
    reading/ cp/ hackathons/ research/ college/ today/ capture/ habits/ notes/ settings/ auth/
      (each: screens/, widgets/, providers.dart)
assets/seed/                 # designed-to-scale.json, saadho.json, cp-sample.json
assets/fonts/                # Geist, Geist Mono
supabase/migrations/         # 0001_init.sql (already written and tested), later additive migrations
test/                        # mirrors lib/
integration_test/            # smoke flows
```

## Database schema (migration `0001_init.sql`)
Already written in `supabase/migrations/0001_init.sql` and verified (it applies on Postgres, RLS isolates users). Every table has `id uuid pk default gen_random_uuid()`, `user_id uuid not null default auth.uid() references auth.users`, `created_at timestamptz default now()`, RLS enabled with policy `user_id = auth.uid()` for all operations.

```
profiles(user_id unique, timezone text default 'Asia/Kolkata', cf_handle text, gcal_calendar_id text)

-- Reading
reading_sources(title, url, kind in ('course','blog'), start_date date, target_days int, status in ('active','archived','done'))
reading_items(source_id fk, title, url, position int, status in ('todo','done','skipped'), done_at timestamptz, note text, unique(source_id, url))

-- CP
cp_lists(name, source text, active bool default false)
cp_problems(list_id fk, contest_id int, idx text, name, rating int, position int, status in ('todo','solved','review','skipped'), solved_at timestamptz, note text, unique(list_id, contest_id, idx))
cp_daily(day date, problem_id fk, unique(user_id, day, problem_id))

-- Work Hub: hackathons
hackathons(name, url, status in ('active','submitted','done','dropped'), theme, team, notes)
hackathon_milestones(hackathon_id fk, title, due_at timestamptz, done bool, kind text, gcal_event_id text)
hackathon_tasks(hackathon_id fk, title, due_at, done bool)

-- Work Hub: research internship
research_projects(name, org, mentor, active bool default true)
research_logs(project_id fk, day date, body text, unique(project_id, day))
research_tasks(project_id fk, title, assigned_by, due_at, status in ('todo','doing','done'), priority int 1..3 default 2, done_at)
research_papers(project_id fk, title, url, status in ('to_read','reading','done'), summary, done_at)
research_ideas(project_id fk, body, status default 'parked')
research_experiments(project_id fk, title, hypothesis, result, day date)

-- College
courses(name, code, attendance_attended int, attendance_total int, min_pct int default 75)
college_tasks(title, course_id fk null, kind in ('assignment','exam','club','other'), due_at, done bool, done_at, gcal_event_id)
gcal_events_cache(gcal_event_id, title, starts_at, ends_at, all_day bool, unique(user_id, gcal_event_id))

-- Cross-cutting
inbox(body text, resolved bool default false)
habits(name, target_per_week int 1..7 default 7)
habit_logs(habit_id fk, day date, unique(habit_id, day))
daily_notes(day date, reflection text, top3 text[], unique(user_id, day))
```
Migrations are additive and forward-only. `test/migrations` is not possible in Dart; keep the SQL verified by running it against a local Postgres/PGlite when it changes (see `progress.md`).

## Data access
`lib/data/db.dart` defines one small typed table repository used by every feature:
```dart
abstract class Db {
  bool get isDemo;
  Future<List<Map<String, dynamic>>> list(String table, {Map<String, Object?> where, String? orderBy, bool ascending = true});
  Future<Map<String, dynamic>?> get(String table, String id);
  Future<List<Map<String, dynamic>>> insert(String table, List<Map<String, dynamic>> rows);
  Future<Map<String, dynamic>> update(String table, String id, Map<String, dynamic> patch);
  Future<void> remove(String table, String id);
}
```
- `DemoDb` applies column defaults, unique constraints and `on delete cascade` like the SQL does, and returns copies.
- `SupabaseDb` maps 1:1 onto `client.from(table)`; Postgres error `23505` becomes a `DbConflict`.
- Feature repos (`lib/data/repos/*`) wrap `Db` and return typed models. Widgets and providers only talk to repos.

## Core domain logic (pure Dart, tested)

**Dates** (`dates.dart`): `LocalDay` = `YYYY-MM-DD` string in the user's zone. `todayLocal(now, tz)`, `startOfDay(day, tz)`, `toLocalDay(instant, tz)`, `daysBetween(a, b)`, `addDays(day, n)`, `formatDue(dueAt, now, tz)` ("Overdue 2d", "Today", "Tomorrow", "In 5d", "Mar 14"). Uses the `timezone` package; default `Asia/Kolkata`.

**Reading planner** (`planner.dart`)
- `todayQuota(remaining, startDate, targetDays, today) = ceil(remaining / max(1, daysLeft))`, `daysLeft = targetDays - daysElapsed`. Nothing stored; recomputed on read, so missed days redistribute automatically.
- The quota is fixed at the start of the local day: items finished today still count toward it, so ticking pages never shrinks or grows today's list.
- Carried over = items an even pace (`total × elapsed / targetDays`) expected done before today but not done.
- A page with no section list becomes a single item; long pages split into `ceil(minutes / 20)` "Part n" items with `#part-n` URLs.

**Reading sources import** (`sitemap.dart`)
- Fetch the page (8s timeout, own user agent), extract same-origin links under the base path in document order with link text as titles (`html` parser), merge in extra pages from `/sitemap.xml`, dedupe, return `{title, url}`. Typed errors: invalid_url, timeout, http, network, empty.
- Seed two sources at `target_days = 30` from bundled snapshots: `designed-to-scale.vercel.app` (a client-rendered SPA with `#/module/n` routes, so its 40 lessons are bundled) and `saadho.arushk.tech` (its 141 `/topics/*` pages).

**CP** (`cp.dart`, `streak.dart`)
- `pickDaily(problems, existingDaily, day)`: if rows exist for `day`, return them; else the first 2 problems with status `todo` (or `review` first) in list order. Idempotent; the caller persists the pick.
- Streak = consecutive local days with at least N solved (default 1, configurable to 2) ending today or yesterday. The same streak function is reused for habits.
- Codeforces sync (`codeforces.dart`): `GET https://codeforces.com/api/user.status?handle=<h>&from=1&count=200`; mark solved when `verdict == "OK"` and `(contestId, index)` matches. Cache 10 minutes in memory. Validate the JSON shape by hand and fail with a typed error, never a crash.
- Lists are imported from pasted CSV/JSON of `(contestId, index)` or Codeforces problem URLs. Bundled sample list for demo mode.

**Attendance**: `canSkip(attended, total, minPct)` returns how many more classes can be missed while staying at or above `minPct`, or how many must be attended to recover.

**Google Calendar** (`gcal.dart`): scope `https://www.googleapis.com/auth/calendar`. Read today's/upcoming events into `gcal_events_cache` on app open and pull-to-refresh. A `college_task` or hackathon milestone with a due date creates or updates a Calendar event and stores `gcal_event_id`. Client behind an interface so tests use a fake; demo mode shows sample events.

**Today view**: sections in order: calendar strip, Reading, CP, Work (top 3 due/overdue across hackathon and research tasks), College (due soon), Habits, Inbox count. Every row has a checkbox that completes it in place (optimistic: update the provider state first, roll back on error). Loaded by one provider that fetches all sections in parallel (`Future.wait`), no waterfall.

## Design tokens (`lib/theme/tokens.dart`)
Dark is default. Light is a warm cream theme. The choice is stored with `shared_preferences`; "system" follows the platform brightness on first launch.

```
light (cream)                      dark (default)
bg         #F4EBE0                 #0C0A09
surface    #FBF6EE                 #151311
surface2   #EFE4D4                 #1C1917
border     #E0D2BD                 #292524
text       #2A2118                 #EDE7DF
muted      #6E5E4C                 #8F867B
accent     #B45309                 #F59E0B
accentFg   #FFFFFF                 #1A1203
accentSoft #FDE9C7                 #2B2007
success    #4D7C0F                 #84CC16
danger     #B42318                 #F87171
```
(Light `muted`/`accent` are slightly darker than the original web spec so text meets WCAG AA on cream.)
- Expose tokens as a `ThemeExtension<PendiColors>`; build `ThemeData` for both modes from them. No raw hex in widgets.
- Radius: card 12, control 8, pill 999. Borders: 1px `border`. No elevation/shadows anywhere (`elevation: 0`, no `Material` shadows).
- Type: Geist (UI) and Geist Mono (labels, numbers, dates). Body 15/1.6. Section label 11 mono uppercase, letter-spacing 0.88 (0.08em), `muted`.
- Spacing scale 4/8/12/16/24/40. Page padding 20 on phones, 40 on wide layouts. Content max width 720 (Today), 960 (other screens).
- Components: checkbox is a 20px rounded square that fills amber with a check; progress bars 4px amber on `surface2`; streak is a small amber flame icon with a mono number.
- Empty states: one line of muted text plus one amber text button. No illustrations.
- Motion: 150ms ease-out fades/slides only; honour `MediaQuery.disableAnimations`.

## Brand
- Name: **Pendi** (always lowercase in the wordmark).
- Wordmark: "pendi" in Geist SemiBold, slightly tight tracking, with the dot of the i drawn as an amber circle. Files: `assets/brand/pendi-wordmark-dark.svg` and `-light.svg` (text converted to paths).
- App icon: a lowercase "p" with the amber dot at its shoulder on a rounded square. `assets/brand/pendi-icon.svg/.png` (dark, default), `pendi-icon-light.*`, and `pendi-icon-foreground.*` (transparent, inside the Android adaptive-icon safe zone).
- Regenerate with `python tool/make_logo.py` (needs `pip install fonttools`). Fonts live in `assets/fonts/`.

## Quality bar
- `flutter analyze` clean with strict lints; `dart format` clean.
- Accessibility: every interactive widget has a semantic label; tap targets ≥ 44 (`androidTapTargetGuideline`, `textContrastGuideline`, `labeledTapTargetGuideline` pass in widget tests for each main screen).
- Today renders from one parallel fetch; first frame of Today under 1s on a mid-range Android in profile mode.
- Every mutation goes through a repo method that validates input and returns a typed `Result`, with optimistic UI.
