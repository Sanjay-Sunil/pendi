#!/usr/bin/env bash
# Usage: scripts/serve-smoke.sh /route1 /route2 ...  (expects a fresh `pnpm build`)
set -u
PORT=3123
fuser -k ${PORT}/tcp >/dev/null 2>&1
pnpm exec next start -p $PORT >/dev/null 2>&1 &
PID=$!
for _ in $(seq 1 60); do curl -s localhost:$PORT >/dev/null && break; sleep 0.5; done
node scripts/smoke.mjs http://localhost:$PORT "$@"
CODE=$?
kill $PID 2>/dev/null; fuser -k ${PORT}/tcp >/dev/null 2>&1
exit $CODE
