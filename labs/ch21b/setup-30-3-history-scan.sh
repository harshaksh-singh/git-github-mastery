#!/usr/bin/env bash
# Hands-on setup for Lab 30.3 (scan full history for planted dummy secrets). Builds server.git
# and the clone "ragdesk" in $GIT_MASTERY_LABS/hands-on/m30-3. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m30-3
fx_ragdesk
fx_ragdesk_notebook
fx_ragdesk_amended
printf 'Lab 30.3 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m30-3     then:  cd ragdesk\n'
