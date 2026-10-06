#!/usr/bin/env bash
# Hands-on setup for Lab 9.7: the same three-branch stack as the replay, in $GIT_MASTERY_LABS/hands-on/m09-7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m09-7
fx_ingest_stack
handson_ready ragkit
