#!/usr/bin/env bash
# Hands-on setup for Lab 12.10 (broken remote-tracking state). Builds "server.git" and your clone "docsearch" in
# $GIT_MASTERY_LABS/hands-on/m12-10. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-10
fx_12_10
printf 'Lab 12.10 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-10     then:  cd docsearch\n'
