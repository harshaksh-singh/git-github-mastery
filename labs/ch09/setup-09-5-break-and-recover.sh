#!/usr/bin/env bash
# Hands-on setup for Lab 9.5: the same repository as the replay, in $GIT_MASTERY_LABS/hands-on/m09-5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m09-5
fx_rerank_clean
git switch -q feat/rerank
handson_ready ragkit
