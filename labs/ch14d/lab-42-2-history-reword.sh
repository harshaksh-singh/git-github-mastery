#!/usr/bin/env bash
# Lab 42.2 replay: fix a typo in an unpushed commit message with the experimental
# "git history reword", and watch every descendant branch move. Failure: the same command on a
# commit that is already pushed rewrites history that origin has. Recovery: put each rewritten
# branch back from its reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d lab-42-2-history-reword
fx_42_2

snip 01-start
run 'cd evalkit'
run 'git log --oneline --graph --all'
run 'git status -sb'

snip 02-dry-run
run_msg 'Add recall metric' 'git history reword --dry-run HEAD~1'
run 'git log --oneline -2'

snip 03-reword
run_msg 'Add recall metric' 'git history reword HEAD~1'
run 'git log --oneline --graph --all'
run 'git status -sb'

snip 04-what-moved
run 'git reflog show -2 main'
run 'git reflog show -2 topic/judge'
note 'Old and new version of the range, commit by commit:'
run "git range-diff origin/main 'main@{1}' main"
note 'Author and committer of the reworded commit, before and after:'
run "git log -1 --format='%an %ad | %cn %cd' 'main@{1}~1'"
run "git log -1 --format='%an %ad | %cn %cd' main~1"

snip 05-failure
note 'The same command, aimed at a commit that origin already has:'
run 'git branch -r --contains HEAD~2'
run_msg 'Add F1 metric' 'git history reword HEAD~2'
run 'git status -sb'
run 'git log --oneline --graph --all'
run_rc 'git -c advice.pushUpdateRejected=false push origin main'

snip 06-recovery
run 'git reflog show -3 main'
run "git reset --hard 'main@{1}'"
run "git branch -f topic/judge 'topic/judge@{1}'"
run 'git status -sb'

snip 07-verification
run 'git log --oneline --graph --all'
run_rc 'git push origin main'
run 'git status -sb'

lab_end
