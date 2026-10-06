#!/usr/bin/env bash
# Final test, lab "debugging" (latencylab): the model solution as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-debugging
final_load debugging

snip 01-observe
run 'cd latencylab'
run 'git status -sb'
run_rc 'sh check-p95.sh'
run 'git log --oneline --graph'
run 'git rev-list --count v1.0..main'

snip 02-bisect
run 'git bisect start main v1.0'
run 'git bisect run sh check-p95.sh'
bad=$(git rev-parse --short refs/bisect/bad)
run 'git bisect log | grep "^git bisect"'
run 'git bisect reset'

snip 03-cause
run "git show --stat --format='%h %an: %s' $bad"
run "git show $bad -- config/client.yaml"
note 'The suspect, tested alone: its parent fails already.'
run 'git log --oneline -1 --grep="Raise the timeout"'
run 'git show HEAD~2:config/client.yaml'

snip 04-repair
run "git revert --no-edit $bad"
run 'git show --stat --format=%B HEAD'
run_rc 'sh check-p95.sh'
run 'cat config/client.yaml'
run 'cd ..'
show_check
final_done
