#!/usr/bin/env bash
# Hands-on setup for Lab 10.3: the same repository as the replay, in $GIT_MASTERY_LABS/hands-on/m10-3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m10-3
fx_gateway_duplicates
handson_ready gateway
