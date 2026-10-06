#!/usr/bin/env bash
# Hands-on setup for Lab 11.1: the prepared scorekit history, in $GIT_MASTERY_LABS/hands-on/m11-1.
# The commits have the same IDs as in the replay (labs/run ch14a/lab-11-1-line-across-rename).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
sandbox_begin hands-on m11-1
fx_scorekit || exit 1
sk_cli_rewrite ../cli-rewrite.py      # used by the failure scenario
sk_handson_ready scorekit
