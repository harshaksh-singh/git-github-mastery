#!/usr/bin/env bash
# Replay of capstone stage 8 (a production hotfix from a release tag, with a backport): the model solution as real transcripts
# for solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin capstone stage-08-hotfix-and-backport
cap_replay 8
