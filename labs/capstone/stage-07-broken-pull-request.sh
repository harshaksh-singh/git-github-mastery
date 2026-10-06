#!/usr/bin/env bash
# Replay of capstone stage 7 (a rebased and force-pushed shared branch): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-07-broken-pull-request
cap_replay 7
