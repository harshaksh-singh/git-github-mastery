#!/usr/bin/env bash
# Replay of capstone stage 3 (a leaked dummy secret in pushed history): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-03-leaked-secret
cap_replay 3
