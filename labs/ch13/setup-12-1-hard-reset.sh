#!/usr/bin/env bash
# Hands-on setup for Lab 12.1 (an accidental hard reset). Builds "retriever" and "retriever-incident" in
# $GIT_MASTERY_LABS/hands-on/m12-1. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-1
fx_12_1
printf 'Lab 12.1 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-1     then:  cd retriever\n'
