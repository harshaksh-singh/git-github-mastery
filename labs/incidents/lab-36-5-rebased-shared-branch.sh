#!/usr/bin/env bash
# Lab 36.5, failure scenario and recovery: "undo" the duplicates by forcing your old series
# back, which undoes the teammate's rebase; then the repair.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-36-5-rebased-shared-branch
incident_load 05-rebased-shared-branch

snip 01-failure
run 'cd you'
old=$(git rev-parse --short 'feature/online-serving@{3}')
new=$(git rev-parse --short 'origin/feature/online-serving@{1}')
note 'The tempting move: go back to my tip from before the pull and force it.'
run "git reset --hard 'feature/online-serving@{1}'"
run 'git push --force'
run 'git log --oneline origin/main..origin/feature/online-serving'
run_rc 'git merge-base --is-ancestor origin/main origin/feature/online-serving'
note "Asha's view after her next fetch:"
run 'git -C ../asha fetch'
run 'git -C ../asha status -sb'
run 'cd ..'
show_check

snip 02-recovery
run 'cd you'
note 'The rebased tip is still in my object database and in my reflog of origin/...:'
run 'git reflog show origin/feature/online-serving -3'
run "git rebase --onto $new $old"
run "git push --force-with-lease=feature/online-serving:$(git rev-parse --short origin/feature/online-serving) origin feature/online-serving"
run 'git -C ../asha pull --ff-only'
run 'cd ..'
show_check
incident_done
