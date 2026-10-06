#!/usr/bin/env bash
# Hands-on setup for Lab 14.1: the same repository as the replay, with the rebase stopped at its
# conflict, in $GIT_MASTERY_LABS/hands-on/m14-1.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
sandbox_begin hands-on m14-1
fx_ragapi_rebase_stopped
handson_ready rag-api
