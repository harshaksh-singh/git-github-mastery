#!/usr/bin/env bash
# Replay of capstone stage 6 (a deleted branch that a teammate needs): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-06-deleted-branch
cap_replay 6
