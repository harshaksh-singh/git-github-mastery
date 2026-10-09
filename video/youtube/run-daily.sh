#!/bin/sh
# Daily unattended run: upload as many pending videos as today's quota allows,
# then rewrite REPORT.md. Safe to run more than once a day: finished videos are
# skipped and a second run stops at once if a first one is still working.
#
# Extra arguments are passed to `upload`, for example:  run-daily.sh --reschedule
# Schedule it with launchd (see README.md, "Run it every day without you").

set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="$ROOT/video/youtube/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$(date +%Y-%m-%d).log"

PY="${PYTHON:-/opt/homebrew/bin/python3}"
[ -x "$PY" ] || PY="$(command -v python3)"

{
  echo "=== run started $(date '+%Y-%m-%d %H:%M:%S %Z') ==="
  # caffeinate -i keeps the Mac awake while the upload runs.
  /usr/bin/caffeinate -i "$PY" "$ROOT/tools/youtube_publish.py" upload --all "$@"
  code=$?
  "$PY" "$ROOT/tools/youtube_publish.py" report
  echo "=== run finished $(date '+%Y-%m-%d %H:%M:%S %Z'), exit code $code ==="
} >>"$LOG" 2>&1

exit "$code"
