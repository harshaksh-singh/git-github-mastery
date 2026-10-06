#!/usr/bin/env bash
# Replay of capstone stage 5 (an accidental reset --hard on unpushed work): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-05-lost-work
cap_replay 5
