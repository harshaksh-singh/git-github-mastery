#!/usr/bin/env bash
# Lab 12.1 replay: an accidental "git reset --hard HEAD~3" (one digit wrong), recovered through
# ORIG_HEAD and the reflog; the same slip without --hard. Failure: the reset is noticed only
# after a new commit, and a blind "reset --hard ORIG_HEAD" trades one loss for another.
# Recovery: anchor both tips, then rebuild the branch with cherry-pick.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-1-hard-reset
fx_12_1

snip 01-start
run 'cd retriever'
run 'git log --oneline'
run 'git status -s'

snip 02-disaster
note 'The plan: drop the last commit. The typo: 3 instead of 1.'
run 'git reset --hard HEAD~3'
run 'git log --oneline'
run 'cat config.yaml'

snip 03-evidence
run 'git reflog -3'
run 'git log --oneline -1 ORIG_HEAD'
run 'git reflog show main -2'

snip 04-recover
run 'git branch rescue/before-reset ORIG_HEAD'
run 'git log --oneline rescue/before-reset'
run 'git reset --hard rescue/before-reset'
run 'git log --oneline -3'
run 'cat config.yaml'

snip 05-do-it-right
note 'Now the operation that was intended: drop only the last commit.'
run 'git reset --hard HEAD~1'
run 'git log --oneline -3'
run 'git branch -D rescue/before-reset'

snip 06-mixed
note 'The same slip without --hard: the branch moves, the files do not.'
run 'git reset HEAD~2'
run 'git log --oneline -1'
run 'git status -s'
run 'cat config.yaml'
run "git reset 'HEAD@{1}'"
run 'git status -s'
run 'git log --oneline -1'

snip 07-failure
run 'cd ../retriever-incident'
run 'git log --oneline'
note 'Two commits and the debug commit are missing. The remedy that worked a minute ago:'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline'

snip 08-recovery-read
run 'git reflog show main'

snip 09-recovery-anchor
run "git branch rescue/mrr 'main@{1}'"
run 'git log --oneline -2 rescue/mrr'
run 'git reset --hard HEAD~1'
run 'git cherry-pick rescue/mrr'

snip 10-verification
run 'git log --oneline'
run 'git range-diff rescue/mrr~1..rescue/mrr HEAD~1..HEAD'
run 'git status -s'
run 'git branch -D rescue/mrr'

lab_end
