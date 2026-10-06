#!/usr/bin/env bash
# Hands-on setup for Lab 35.1. Builds three repositories: annotator, batch-infer and prompt-router, each with a SYMPTOM.txt card beside it
# in $GIT_MASTERY_LABS/hands-on/m35-1. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m35-1
fx_35_1
printf 'Lab 35.1 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m35-1     then:  cat annotator.SYMPTOM.txt\n'
