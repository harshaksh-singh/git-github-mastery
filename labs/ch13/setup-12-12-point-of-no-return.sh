#!/usr/bin/env bash
# Hands-on setup for Lab 12.12 (the point of no return). Builds "featurestore",
# "featurestore-damaged", the clone "teammate" and "featurestore-backup.bundle" in
# $GIT_MASTERY_LABS/hands-on/m12-12. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-12
fx_12_12
printf 'Lab 12.12 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-12     then:  cd featurestore\n'
