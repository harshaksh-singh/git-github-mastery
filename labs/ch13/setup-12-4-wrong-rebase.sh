#!/usr/bin/env bash
# Hands-on setup for Lab 12.4 (a wrong rebase). Builds "evalharness" and "evalharness-incident" in
# $GIT_MASTERY_LABS/hands-on/m12-4. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-4
fx_12_4
printf 'Lab 12.4 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-4     then:  cd evalharness\n'
