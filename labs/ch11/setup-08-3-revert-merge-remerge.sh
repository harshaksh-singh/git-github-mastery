#!/usr/bin/env bash
# Hands-on setup for Lab 8.3 (revert a merge, then re-merge). Builds the repository "pipeline"
# in $GIT_MASTERY_LABS/hands-on/m08-3. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-3
fx_08_3
printf 'Lab 8.3 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-3     then:  cd pipeline\n'
