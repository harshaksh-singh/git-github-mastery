#!/usr/bin/env bash
# Lab 37.1, failure scenario and recovery: main is restored first, without saving the
# forced-in commits and without fixing the cause. The cause fires again.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-37-1-force-push-wrong-branch
incident_load 02-force-push-wrong-branch

snip 01-failure
run 'cd you'
run 'git fetch'
note 'The tempting move: put main back at once.'
run "git push --force-with-lease=main:$(git rev-parse --short origin/main) origin main"
note "Which branch on the server holds Asha's two commits now?"
run 'git ls-remote origin'
note 'Asha, told that main is fixed, publishes her branch the way she did before:'
run 'cd ../asha'
run_rc 'git push'
run 'cd ..'
show_check

snip 02-recovery
run 'cd asha'
note 'The rejection is the only thing that saved main this time. Fix the cause, then push by name:'
run 'git config unset push.default'
run 'git push -u origin feature/dedupe'
run 'git branch -vv'
run 'cd ..'
show_check
incident_done
