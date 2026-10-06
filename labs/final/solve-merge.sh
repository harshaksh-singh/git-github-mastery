#!/usr/bin/env bash
# Final test, lab "merge" (answerbank): the model diagnosis and repair as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-merge
final_load merge

snip 01-observe
run 'cd you'
run 'git status -sb'
run_rc 'sh tests/smoke.sh'
run 'git log --oneline --graph'

snip 02-evidence
run 'git grep -n "fetch_answer\|get_answer"'
run 'git diff --stat HEAD~1 HEAD'
run 'git diff --stat HEAD~2 HEAD~1'
note 'Did the second merge have to combine any file? Which paths did each side change since the merge base?'
run 'git diff --name-only HEAD~1...origin/feature/bulk-export'
run 'git diff --name-only origin/feature/bulk-export...HEAD~1'

snip 03-repair
run "sed -e 's/store\.fetch_answer(/store.get_answer(/' answerbank/export.py > export.new && mv export.new answerbank/export.py"
run 'git diff'
run_rc 'sh tests/smoke.sh'
run 'git commit -q -a -m "Call get_answer in the bulk export"'
run 'git push'
run 'git log --oneline --graph -4'
run 'cd ..'
show_check
final_done
