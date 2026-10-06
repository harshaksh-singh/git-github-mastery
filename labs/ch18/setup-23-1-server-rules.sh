#!/usr/bin/env bash
# Hands-on setup for the local rehearsal of Lab 23.1: an unprotected bare server, your clone,
# and the hook file rules/pre-receive, not yet installed.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m23-1
scenario_rules
require_ref "$LAB_DIR/server/ticket-router.git" refs/heads/main
[ -f "$LAB_DIR/rules/pre-receive" ] || { echo 'fixture: hook file missing' >&2; exit 1; }

printf 'Lab 23.1 (local rehearsal) is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m23-1\n'
printf 'First command of the lab:  ls server/ticket-router.git/hooks | grep -vc sample\n'
