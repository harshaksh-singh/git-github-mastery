#!/usr/bin/env bash
# Hands-on setup for Lab 10.4: the same repository as the replay, in $GIT_MASTERY_LABS/hands-on/m10-4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/retriever.sh"
sandbox_begin hands-on m10-4
fx_retriever || exit 1
rt_handson_ready retriever
