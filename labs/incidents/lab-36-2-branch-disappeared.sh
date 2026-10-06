#!/usr/bin/env bash
# Lab 36.2, failure scenario and recovery: push the squash-merged branch back and look at the
# pull request it would produce; then the clean way.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-36-2-branch-disappeared
incident_load 08-branch-disappeared

snip 01-failure
run 'cd asha'
tip=$(git reflog --format=%h --grep-reflog='commit: Validate prompt variables' | head -1)
note 'The tempting move: recreate the branch under its old name and push it.'
run "git branch feature/prompt-versioning $tip"
run 'git push origin feature/prompt-versioning'
note 'What a pull request from it into main would show:'
run 'git log --oneline origin/main..origin/feature/prompt-versioning'
run 'git diff --stat origin/main...origin/feature/prompt-versioning'
run 'cd ..'
show_check

snip 02-recovery
run 'cd asha'
run 'git push origin --delete feature/prompt-versioning'
run 'git switch -c feature/prompt-validation main'
run 'git cherry-pick feature/prompt-versioning'
run 'git push -u origin feature/prompt-validation'
run 'git diff --stat feature/prompt-versioning feature/prompt-validation'
run 'git branch -D feature/prompt-versioning'
run 'cd ..'
show_check
incident_done
