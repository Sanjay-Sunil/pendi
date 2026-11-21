# Pendi

A calm, mobile-first daily planner: reading, competitive programming, hackathons, research, and college in one Today screen. Flutter + Supabase.

## Run it (demo mode, no backend)

```
flutter pub get
flutter run            # Android device, or: flutter run -d chrome
```

Demo mode keeps data in memory and seeds sample reading, CP, and calendar data. To use your own Supabase and Google account, follow [docs/SETUP.md](docs/SETUP.md) and run with `--dart-define-from-file=env.json`.

## Develop

| Task | Command |
| --- | --- |
| Full gate (format, analyze, test, web build) | `tool/gate.sh` |
| Smoke flows in headless Chrome | `tool/e2e.sh` |
| Live-network extractor tests | `flutter test test/integrations --dart-define=LIVE_NETWORK=true` |
| Regenerate logo | `pip install fonttools && python tool/make_logo.py` |

Plan and decisions: `plan.md`, `build.md`, `progress.md`.
