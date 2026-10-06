#!/usr/bin/env bash
# Model solution of exercise 12.9 (Level 4): a branch reset by "git switch -C", found in the
# branch's own reflog and rebuilt on the current main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m12-batchscore
ex_load m12-batchscore
cd ravi || exit 1

snip 01-observe
run 'git status -sb'
run 'git branch -vv'
run 'git log --graph --oneline --all'

snip 02-head-reflog
run 'git reflog -9'
run 'git log -1 --format="%h %s" ORIG_HEAD'

snip 03-branch-reflog
run 'git reflog show feature/retry-budget'

snip 04-anchor
run "git branch rescue 'feature/retry-budget@{2}'"
run 'git log --oneline main..rescue'
run 'git show rescue:batchscore/worker.py | grep budget.left'

snip 05-rebuild
run 'git rebase --onto rescue main feature/retry-budget'
run 'git rebase main'
run 'git log --graph --oneline --all'

snip 06-verify
run 'git range-diff rescue~3..rescue main..HEAD~1'
run 'git diff --stat rescue HEAD'
run 'git branch -D rescue'
run 'git status -sb'
run 'cd ..'
show_check
ex_done
