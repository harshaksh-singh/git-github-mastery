#!/usr/bin/env bash
# Hands-on setup for Lab 9.4: the same repository as the replay, in $GIT_MASTERY_LABS/hands-on/m09-4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m09-4
fx_rerank_conflict
handson_ready ragkit
