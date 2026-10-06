#!/usr/bin/env bash
# Lab 36.1, failure scenario and recovery: "undo the reset" with a second hard reset, which
# throws away the commit made after the accident; then the way back.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-36-1-hard-reset
incident_load 01-hard-reset

snip 01-failure
run 'cd ravi'
note 'The tempting move: put the branch back where it was before the accident.'
run "git reset --hard 'feature/escalation-rules@{2}'"
run 'git log --oneline'
run 'cd ..'
show_check

snip 02-recovery
run 'cd ravi'
run 'git reflog show feature/escalation-rules -3'
note 'The reflog also recorded the second reset. Name the old tip, undo the reset, then add:'
run 'git branch rescue/before-reset'
run "git reset --keep 'feature/escalation-rules@{1}'"
run 'git cherry-pick origin/main..rescue/before-reset'
run 'git fsck --lost-found'
run 'git cat-file -p $(ls .git/lost-found/other) > rules/priority.yaml'
run 'cd ..'
show_check
incident_done
