#!/usr/bin/env bash
# Final test, practical lab "fork" (section 13): the project "spanlog".
# Builds upstream.git (the open-source project), fork.git (your fork, the part GitHub plays) and
# your clone you/. You committed on the main branch of your fork, and the project has moved.
# Read TASK.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final fork
final_begin fork

final_server upstream.git
quiet 'git clone upstream.git maintainer'
cd maintainer || exit 1
as asha
mkdir -p spanlog
printf 'import time\n\n\ndef stamp():\n    return time.strftime("%%Y-%%m-%%dT%%H:%%M:%%S")\n' > spanlog/clock.py
printf 'def export(span, sink):\n    sink.write(span.to_json())\n' > spanlog/export.py
printf '# Contributing\n\nOpen pull requests from a topic branch that starts at the current main of this\nrepository. Keep the main branch of your fork identical to ours.\n' > CONTRIBUTING.md
_c 'Add span clock and exporter'
quiet 'git push origin main'
cd "$LAB_DIR" || exit 1

# The Fork button, in plain Git, and your clone of the fork.
as you
quiet 'git clone --bare upstream.git fork.git'
final_clone you fork.git
cd you || exit 1
printf 'import time\n\n\ndef stamp():\n    return time.strftime("%%Y-%%m-%%dT%%H:%%M:%%SZ", time.gmtime())\n' > spanlog/clock.py
_c 'Emit UTC timestamps'
mkdir -p tests
printf 'from spanlog.clock import stamp\n\n\ndef test_stamp_is_utc():\n    assert stamp().endswith("Z")\n' > tests/test_clock.py
_c 'Test that timestamps are UTC'
quiet 'git push origin main'
cd "$LAB_DIR/maintainer" || exit 1

# Meanwhile the project moves.
as asha
printf 'import random\n\n\ndef sampled(rate):\n    return random.random() < rate\n' > spanlog/sampling.py
_c 'Add span sampling'
printf 'def export(span, sink, pretty=False):\n    sink.write(span.to_json(indent=2 if pretty else None))\n' > spanlog/export.py
_c 'Add a pretty option to the exporter'
quiet 'git push origin main'
final_note upstream "$(git rev-parse HEAD)"
cd "$LAB_DIR" || exit 1
rm -rf maintainer

final_end
final_ready
