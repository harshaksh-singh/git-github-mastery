#!/usr/bin/env bash
# Hands-on setup for Lab 14.3 (a pre-push guard). Builds "server.git", "gateway", "asha" and the
# directory "hooks" in $GIT_MASTERY_LABS/hands-on/m14-3. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m14-3
fx_14_3
printf 'Lab 14.3 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m14-3     then:  cd gateway\n'
