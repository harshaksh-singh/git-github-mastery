#!/usr/bin/env bash
# Replay of incident 8 (a branch that appears to have disappeared): where the branch went on
# the server and in the clone, what is in main, what was never pushed, and the recovery.
# Transcripts for Chapter 30 and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-08-branch-disappeared
incident_load 08-branch-disappeared

snip 01-observe
run 'cd asha'
run 'git status -sb'
run 'git branch -a'
run 'git ls-remote origin'

snip 02-reflog
note 'The branch reflog went with the branch. The HEAD reflog is still here:'
run_rc 'git reflog show feature/prompt-versioning'
run "git reflog --format='%h %gd %gs'"

snip 03-why-gone
run 'git config get --show-origin fetch.prune'
note 'What is on main now, and who put it there?'
run "git log -2 --format='%h author %an, committer %cn: %s' main"
run 'git show --stat --format=%s main'

snip 04-classify
tip=$(git reflog --format=%h --grep-reflog='commit: Validate prompt variables' | head -1)
note 'The last commit made on the lost branch, from the HEAD reflog:'
run "git log --oneline main..$tip"
note 'Patch IDs cannot see through a squash: every commit looks unmerged.'
run "git cherry -v main $tip"
note 'Trees can. What does the old tip have that main does not?'
run "git diff --stat main $tip"
run "git diff --stat main $tip~1"

snip 05-anchor
run "git branch rescue/prompt-versioning $tip"
run 'git branch -vv'

snip 06-recover
run 'git switch -c feature/prompt-validation main'
run 'git cherry-pick rescue/prompt-versioning'
run 'git push -u origin feature/prompt-validation'

snip 07-verify
note 'What a pull request for the new branch would show:'
run 'git log --oneline origin/main..origin/feature/prompt-validation'
run 'git diff --stat origin/main...origin/feature/prompt-validation'
run 'git diff --stat rescue/prompt-versioning feature/prompt-validation'
run 'git branch -D rescue/prompt-versioning'
run 'cd ..'
show_check
incident_done
