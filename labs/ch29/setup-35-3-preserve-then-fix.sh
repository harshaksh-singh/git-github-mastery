#!/usr/bin/env bash
# Hands-on setup for Lab 35.3. Builds the repository guardrail, stopped in the middle of a backport, and guardrail.HANDOVER.txt
# in $GIT_MASTERY_LABS/hands-on/m35-3. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m35-3
fx_35_3
printf 'Lab 35.3 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m35-3     then:  cat guardrail.HANDOVER.txt\n'
