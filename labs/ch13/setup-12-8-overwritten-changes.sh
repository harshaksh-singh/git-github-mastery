#!/usr/bin/env bash
# Hands-on setup for Lab 12.8 (overwritten changes and a cleared stash). Builds "finetune" and "finetune-incident" in
# $GIT_MASTERY_LABS/hands-on/m12-8. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-8
fx_12_8
printf 'Lab 12.8 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-8     then:  cd finetune\n'
