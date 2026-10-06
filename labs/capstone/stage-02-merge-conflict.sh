#!/usr/bin/env bash
# Replay of capstone stage 2 (a merge conflict between two feature branches): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-02-merge-conflict
cap_replay 2
