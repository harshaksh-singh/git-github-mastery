#!/usr/bin/env bash
# Hands-on setup for Lab 12.2 (a deleted branch). Builds "server.git" and your clone "reranker" in
# $GIT_MASTERY_LABS/hands-on/m12-2. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-2
fx_12_2
printf 'Lab 12.2 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-2     then:  cd reranker\n'
