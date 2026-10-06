#!/usr/bin/env bash
# Hands-on setup for Lab 12.5 (a bad merge). Builds "promptstore" and "promptstore-incident" in
# $GIT_MASTERY_LABS/hands-on/m12-5. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-5
fx_12_5
printf 'Lab 12.5 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-5     then:  cd promptstore\n'
