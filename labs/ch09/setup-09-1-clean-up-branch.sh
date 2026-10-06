#!/usr/bin/env bash
# Hands-on setup for Lab 9.1: the same messy branch as the replay, in $GIT_MASTERY_LABS/hands-on/m09-1.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
sandbox_begin hands-on m09-1
fx_metrics_messy
handson_ready ragkit
