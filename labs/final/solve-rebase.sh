#!/usr/bin/env bash
# Final test, lab "rebase" (citecheck): the model solution as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-rebase
final_load rebase

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git log --oneline --graph --all --decorate'
run 'git log --oneline --name-status origin/main..feature/span-match'

snip 02-rebase
run 'git branch backup/span-match'
LAB_MSG='Add overlap scoring'
export LAB_MSG
run_todo_cmd '{ sed -n "1,2p" "$f"; sed -n "3p" "$f" | sed "s/^pick/reword/"; sed -n "5p" "$f" | sed "s/^pick/fixup/"; sed -n "4p" "$f"; } > "$f.new" && mv "$f.new" "$f"' 'git rebase -i --autosquash origin/main'
unset LAB_MSG

snip 03-verify
run 'git log --oneline --name-status origin/main..feature/span-match'
run 'git range-diff origin/main backup/span-match feature/span-match'
note 'Proof of content: the new tip against a test merge of the old branch with origin/main.'
run 'git merge-tree --write-tree origin/main backup/span-match'
run "git rev-parse 'feature/span-match^{tree}'"
run 'git branch -D backup/span-match'
run 'cd ..'
show_check
final_done
