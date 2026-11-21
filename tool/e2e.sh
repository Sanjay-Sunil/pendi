#!/usr/bin/env bash
# Runs integration_test/ smoke flows in headless Chrome via chromedriver.
set -euo pipefail
export CHROME_EXECUTABLE=${CHROME_EXECUTABLE:-$(command -v chromium || command -v google-chrome-stable)}
chromedriver --port=4444 >/dev/null 2>&1 &
DRIVER=$!
trap 'kill $DRIVER 2>/dev/null' EXIT
sleep 1
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/smoke_test.dart \
  -d web-server --browser-name=chrome --headless
