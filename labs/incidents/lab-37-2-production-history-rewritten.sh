#!/usr/bin/env bash
# Lab 37.2, failure scenario and recovery: the old history is forced back without carrying over
# the commit that was shipped on the rewritten one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-37-2-production-history-rewritten
incident_load 04-production-history-rewritten

snip 01-failure
run 'cd you'
run 'git fetch'
note 'The tempting move: my production is the good history, so force it.'
run "git push --force-with-lease=production:$(git rev-parse --short origin/production) origin production"
run 'cd ..'
show_check

snip 02-recovery
note "The commit that was shipped in between is still in its author's clone. The realign step finds it:"
run 'cd asha'
run 'git fetch'
run 'git cherry -v origin/production production'
note 'Two "+" lines. One is the rewrite, which is being retired. The other is real work:'
run 'git branch rescue/footer production'
run 'git reset --keep origin/production'
run 'git cherry-pick rescue/footer'
run 'git push'
run 'git branch -D rescue/footer'
run 'cd ../ravi'
run 'git fetch'
run 'git reset --keep origin/production'
run 'cd ../you'
run 'git switch production'
run 'git pull --ff-only'
run 'cd ..'
show_check
incident_done
