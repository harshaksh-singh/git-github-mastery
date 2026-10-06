#!/usr/bin/env bash
# Hands-on setup for the Git half of Lab 23.3: three open branches on the server, each blocked
# in a different way, and the script preflight.sh in the sandbox root.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m23-3
scenario_three_blocks
require_ref "$LAB_DIR/server/ticket-router.git" refs/heads/fix/threshold
require_ref "$LAB_DIR/server/ticket-router.git" refs/heads/docs/queues
[ -f "$LAB_DIR/preflight.sh" ] || { echo 'fixture: preflight.sh missing' >&2; exit 1; }

printf 'Lab 23.3 (Git half) is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m23-3\n'
printf 'First command of the lab:  cat preflight.sh\n'
