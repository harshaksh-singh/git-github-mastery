#!/usr/bin/env bash
# Hands-on setup for Lab 31.1 (the secret-leak tabletop). Builds server.git, your clone
# "ragdesk", the teammates' clones "asha" and "ravi", the stand-in key issuer "provider" and
# the hook kit "kit" in $GIT_MASTERY_LABS/hands-on/m31-1. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m31-1
fx_ragdesk
printf 'Lab 31.1 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m31-1\n'
