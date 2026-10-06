#!/usr/bin/env bash
# Replay of incident 1 (an accidental "git reset --hard"): diagnosis and recovery as real
# transcripts for Chapter 30 and solutions/incident-01-hard-reset.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-01-hard-reset
incident_load 01-hard-reset

snip 01-observe
run 'cd ravi'
run 'git status -sb'
run 'git branch -vv'
run 'git log --oneline --graph --all'

snip 02-reflog
run 'git reflog show feature/escalation-rules'
note 'Ravi suspects "git pull". Does the HEAD reflog record a pull at all?'
run_rc "git reflog | grep -c pull"

snip 03-anchor
run "git branch rescue/before-reset 'feature/escalation-rules@{2}'"
run 'git log --oneline origin/main..rescue/before-reset'
run 'git diff --stat origin/main...rescue/before-reset'

snip 04-staged
run 'git fsck --lost-found'
run 'ls .git/lost-found/other'
blob=$(ls .git/lost-found/other)
run "git cat-file -p ${blob:0:7}"

snip 05-recover
run 'git cherry-pick origin/main..rescue/before-reset'
run "git cat-file -p ${blob:0:7} > rules/priority.yaml"
run 'git status -sb'

snip 06-verify
run 'git log --oneline --graph feature/escalation-rules'
run 'git range-diff origin/main rescue/before-reset HEAD'
run 'cat rules/routing.yaml'
run 'cd ..'
show_check

snip 07-cleanup
run 'git -C ravi branch -D rescue/before-reset'
incident_done
