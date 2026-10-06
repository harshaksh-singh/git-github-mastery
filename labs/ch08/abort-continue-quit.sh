#!/usr/bin/env bash
# The three ways out of a stopped merge: --continue, --abort, --quit. Chapter 8, section 8.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 abort-continue-quit

quiet 'ek_creative_judge'

snip 01-continue-too-early
run_rc 'git merge feature/creative-judge'
run_rc 'git merge --continue'

snip 02-abort
run 'git merge --abort'
run 'git status --short --branch'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"
run 'git reflog -2'

snip 03-nothing-in-progress
run_rc 'git merge --abort'
run_rc 'git merge --continue'

snip 04-quit
run_rc 'git merge feature/creative-judge'
run_rc 'git merge --quit'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"
run 'git status'

snip 05-after-quit
note 'The merge is forgotten, the half-merged files are not. A commit made now has ONE parent:'
quiet "ek_resolve_dropping '^temperature: 0.7' config/eval.yaml"
run 'git add config/eval.yaml'
run 'git commit -q -m "Resolve temperature conflict"'
run 'git log --oneline --graph --all'
run 'git branch --no-merged'

# Put main back to where it was before that commit, for the next snippet.
quiet 'git reset --hard HEAD~1'

snip 06-quit-cleanup
note 'The clean way back after --quit: reset the index and the files the merge touched.'
quiet 'git merge feature/creative-judge'
run 'git merge --quit'
run_rc 'git merge --abort'
run 'git reset --merge'
run 'git status --short --branch'

snip 07-dirty-tree
note 'An uncommitted edit in a file the merge does not touch survives merge and abort.'
run 'echo "# evalkit" > NOTES.md'
run_rc 'git merge feature/creative-judge'
run 'git status --short'
run 'git merge --abort'
run 'git status --short'

snip 08-autostash
note 'An uncommitted edit in a file the merge DOES touch stops the merge before it starts...'
quiet 'rm NOTES.md'
run 'echo "Be concise." >> prompts/judge.txt'
run_rc 'git merge feature/creative-judge'
note '...unless Git stashes it for you.'
run_rc 'git merge --autostash feature/creative-judge'
run "ls .git | grep -E 'MERGE|ORIG_HEAD'"
run 'git merge --abort'
run 'git status --short'

lab_end
