#!/usr/bin/env bash
# Hands-on setup for Lab 12.6 (commits on the wrong branch). Builds "server.git", "ingest" and "ingest-incident" in
# $GIT_MASTERY_LABS/hands-on/m12-6. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-6
fx_12_6
printf 'Lab 12.6 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-6     then:  cd ingest\n'
