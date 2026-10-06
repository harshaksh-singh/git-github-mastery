#!/usr/bin/env bash
# Hands-on setup for Lab 15.1: the same repositories as the replay, in $GIT_MASTERY_LABS/hands-on/m15-1.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
sandbox_begin hands-on m15-1
fx_docqa_submodule
fx_ravi_clone
handson_ready doc-qa
