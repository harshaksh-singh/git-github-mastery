#!/usr/bin/env bash
# Hands-on setup for Lab 12.3 (a deleted commit). Builds "embedder" in
# $GIT_MASTERY_LABS/hands-on/m12-3. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-3
fx_12_3
printf 'Lab 12.3 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-3     then:  cd embedder\n'
