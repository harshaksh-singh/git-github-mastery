#!/usr/bin/env bash
# Hands-on setup for Lab 12.9 (a wrong cherry-pick). Builds "apigw" and "apigw-incident" in
# $GIT_MASTERY_LABS/hands-on/m12-9. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-9
fx_12_9
printf 'Lab 12.9 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-9     then:  cd apigw\n'
