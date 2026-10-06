#!/usr/bin/env bash
# Final test, lab "remote" (intentmap): the model diagnosis and repair as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-remote
final_load remote

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git branch -vv'
run 'git remote -v'
run 'git branch -r'

snip 02-evidence
run 'git ls-remote --heads origin'
run 'git ls-remote --heads staging'
run_rc "git rev-parse --abbrev-ref 'feature/slot-carryover@{upstream}'"
run_rc "git rev-parse --abbrev-ref 'feature/slot-carryover@{push}'"
run 'git push --dry-run --verbose'
run 'git config get --show-origin --show-scope remote.pushDefault'
run 'git config get --default "simple (the built-in default)" push.default'

snip 03-repair
run 'git config unset remote.pushDefault'
run 'git push -u origin feature/slot-carryover'
run 'git push staging --delete feature/slot-carryover'

snip 04-verify
run 'git branch -vv'
run "git rev-parse --abbrev-ref 'feature/slot-carryover@{push}'"
run 'git ls-remote --heads origin'
run 'git ls-remote --heads staging'
run 'git -C ../asha fetch'
run 'cd ..'
show_check
final_done
