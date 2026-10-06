#!/usr/bin/env bash
# Hands-on setup for Lab 30.1, local part (a push-time secret check in plain Git). Builds
# server.git, the clone "triage" and the hook kit in $GIT_MASTERY_LABS/hands-on/m30-1.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m30-1
fx_triage
printf 'Lab 30.1 (local part) is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m30-1\n'
