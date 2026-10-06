#!/usr/bin/env bash
# Hands-on setup for Lab 10.2: the same repository as the replay, in $GIT_MASTERY_LABS/hands-on/m10-2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m10-2
fx_gateway_conflict
handson_ready gateway
