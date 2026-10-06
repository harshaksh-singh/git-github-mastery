#!/usr/bin/env bash
# Hands-on setup for Exercise 21.6: a pull request branch that lists commits you did not write.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on x21-6
scenario_x21_foreign
require_ref "$LAB_DIR/server/chunker.git" refs/pull/23/head
require_ref "$LAB_DIR/server/chunker.git" refs/heads/feature/semantic-split
setup_done 21.6 x21-6/you/chunker 'git status -sb'
