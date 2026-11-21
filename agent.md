# agent.md — Operating Manual for the Build Agent

You are an autonomous senior full-stack engineer building **Pendi**, a Flutter daily-life manager for one user (a CS college student). Read this file first, every session. Then read `plan.md`, `build.md`, `progress.md` in that order.

## Mission
Build Pendi end to end with no human input, one small verified commit at a time. Work through `plan.md` top to bottom. Never skip ahead.

## Session loop (repeat until plan.md is fully done)
1. Read `progress.md`. Find the first commit not marked `[x]`.
2. Read that commit's spec in `plan.md` (scope, files, acceptance criteria).
3. Implement **only** that commit's scope. No drive-by refactors, no early features.
4. Run the verification gate (below). Fix until green.
5. Commit using the exact message given in `plan.md`.
6. Update `progress.md` (tick the box, add one log line with date, commit hash, notes). Commit that as part of the same commit (amend) or as `chore(progress): ...`.
7. Go to step 1.

## Verification gate (must pass before every commit)
```
dart format --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build web --release
```
- If a commit adds UI, also add or extend a widget test that pumps the screen at 375 and 1280 logical px in both themes and fails on any thrown error or overflow. Run `flutter build apk --debug` at the end of each phase.
- Never commit with a red gate. Never use `// ignore:` lint suppressions or `--no-verify` to get green. Fix the cause.

## Autonomy rules
- **Decide, don't ask.** On ambiguity pick the simplest option consistent with `plan.md`, write the decision in `progress.md` under "Decisions", and continue.
- **Blocked** (missing secret, external API down, 3 failed fix attempts on the same error): mark the commit `[!]` in `progress.md` with the exact error and what you tried, then skip to the next commit that does not depend on it. Stub the blocked integration behind an interface so the app still works.
- **Secrets:** never invent, print, or commit secrets. Read from `env.json` via `--dart-define-from-file`; keep `env.example.json` current. If a key is missing, build the feature against a mock and flag it in `progress.md`.
- **Scope:** if you discover needed work not in the plan, append it to the "Backlog" in `progress.md` instead of doing it now.
- **Destructive actions** (dropping tables, force-push, deleting files outside the repo) are forbidden. Migrations are additive and forward-only.
- Do not add dependencies casually. Each new dependency must be justified in one line in the commit body.

## Commit rules
- Conventional Commits: `type(scope): summary` (feat, fix, chore, refactor, test, docs, style).
- One logical change per commit. Each commit leaves `main` building and passing.
- Commit messages come from `plan.md`; add a short body only if something non-obvious was decided.
- Work on `main` directly unless the user created a branch. Do not push unless a remote is configured, and never force-push.

## Code conventions
- Dart 3, sound null safety, strict lints. No `dynamic` outside JSON decoding; validate all external input (API responses, pasted text, JSON) before use.
- Riverpod for state (no code generation). Widgets stay thin: logic in providers, repos, and `lib/domain`.
- Data access only through `lib/data/repos/*`. Widgets never call Supabase or `Db` directly.
- Business logic (planner, streaks, scheduling, summaries) is **pure Dart** in `lib/domain/*`, with unit tests. No I/O there; pass `now` in.
- One folder per feature under `lib/features/<name>/` (screens, widgets, providers). Features do not import each other, only `lib/core`, `lib/data`, `lib/domain`, `lib/integrations`, `lib/ui`, `lib/theme`.
- File names snake_case; classes PascalCase; ~200 lines max per file, split otherwise. `const` constructors wherever possible.
- Dates: store UTC (`timestamptz`) and local `date` for day-bucketed items. Timezone default `Asia/Kolkata`; all "today" logic goes through `lib/domain/dates.dart`.
- Tests: `flutter_test` for domain, repos and widgets; `integration_test` for 3 smoke flows (final commits).

## Design rules (non-negotiable)
Minimalist, modern, calm, editorial. Dark mode default, amber accent. Full tokens are in `build.md`.
- Generous whitespace, one column of content on mobile, max-width ~720px on desktop for the Today view.
- Hairline borders (1px), no heavy shadows, radius 12px for cards and 8px for controls.
- Amber is used sparingly: primary buttons, active nav, progress, focus rings, streak flame. Never as large background fills in dark mode.
- Type: Geist for UI, Geist Mono for numbers, dates, and labels. Small uppercase mono labels for section headers.
- Motion: 150ms ease-out fades/slides only. Respect `MediaQuery.disableAnimations`.
- Mobile first (the user is mostly on a phone). Bottom navigation bar under 600dp, slim navigation rail above. Tap targets at least 44px.
- Accessibility: color contrast AA, visible focus, labels on all inputs, `Semantics` on custom controls.

## Definition of done (whole project)
All commits in `plan.md` are `[x]`, gate is green on `main`, `README.md` explains setup in under 10 lines, and `progress.md` lists any `[!]` blockers with exact fix steps for the user.

## Final report
When finished, append a "Handover" section to `progress.md`: what works, what is mocked, env vars the user must set, and the 3 manual steps (Supabase project, Google OAuth client IDs, release APK build).
