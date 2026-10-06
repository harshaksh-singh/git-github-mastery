#!/usr/bin/env bash
# Hands-on setup for Lab 8.2 (revert a pushed commit). Builds a bare "server.git" and the two
# clones "you" and "asha" in $GIT_MASTERY_LABS/hands-on/m08-2. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-2
fx_08_2
printf 'Lab 8.2 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-2     then:  cd you\n'
