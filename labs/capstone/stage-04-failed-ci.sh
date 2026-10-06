#!/usr/bin/env bash
# Replay of capstone stage 4 (a failed CI run on a pull request): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-04-failed-ci
cap_replay 4
