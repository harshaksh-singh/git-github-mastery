#!/usr/bin/env bash
# Lab 36.3, failure scenario and recovery: the push to the team repository is rejected, and
# forcing it removes a teammate's commit; then the repair from the teammate's clone.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-36-3-commit-local-not-remote
incident_load 10-commit-local-not-remote

snip 01-failure
run 'cd ravi'
run_rc 'git push upstream main'
note 'The tempting move: it is "only" rejected, so force it.'
run 'git push --force upstream main'
run 'git ls-remote upstream main'
run 'cd ..'
show_check

snip 02-recovery
note 'The removed commit is still in the clone of the person who made it.'
run 'cd you'
run 'git fetch'
run 'git status -sb'
run "git log --format='%h %an: %s' origin/main..main"
note 'A second trap. "git pull --rebase" looks like the way to put my commit on top:'
run 'git pull --rebase'
run 'git log --oneline -3'
note 'My commit is gone from main. The rebase judged it to be part of the old upstream history'
note '(it is in the reflog of origin/main), so it did not replay it. ORIG_HEAD still names it:'
run 'git log --oneline -1 ORIG_HEAD'
run 'git cherry-pick ORIG_HEAD'
run 'git push'
run 'cd ../ravi'
run 'git fetch upstream'
run 'git branch --set-upstream-to=upstream/main main'
run 'git pull --ff-only'
run 'git config set remote.pushDefault upstream'
run 'cd ..'
show_check
incident_done
