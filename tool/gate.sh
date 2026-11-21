#!/usr/bin/env bash
# The verification gate from agent.md.
set -euo pipefail
dirs=(lib test)
[ -d integration_test ] && dirs+=(integration_test)
dart format --set-exit-if-changed "${dirs[@]}"
flutter analyze
flutter test
flutter build web --release
