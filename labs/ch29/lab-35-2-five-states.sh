#!/usr/bin/env bash
# Lab 35.2 replay: five repositories, each stopped in the middle of a different operation, read
# from the files in .git alone; git status is used only to check the answer. Failure scenario:
# the state files of a merge are deleted by hand and the "merge" is committed with one parent.
# Recovery: take the commit off the branch with git reset --keep and merge again.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 lab-35-2-five-states
fx_35_2

snip 01-survey
run 'for d in case-1 case-2 case-3 case-4 case-5; do echo "== $d"; cat $d/.git/HEAD; ls $d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT"; done'

snip 02-case-1
run 'cd case-1'
run 'cat .git/REVERT_HEAD'
run 'git cat-file -p $(cat .git/REVERT_HEAD) | tail -1'
run 'cat .git/MERGE_MSG'
run 'git status | head -2'

snip 03-case-2
run 'cd ../case-2'
run 'cat .git/BISECT_START'
run 'cat .git/BISECT_LOG'
run 'ls .git/refs/bisect'
run 'git status | head -2'

snip 04-case-3
run 'cd ../case-3'
run 'cat .git/MERGE_HEAD'
run 'git cat-file -p $(cat .git/MERGE_HEAD) | tail -1'
run 'cat .git/MERGE_MSG'
run 'cat .git/ORIG_HEAD'
run 'git status | head -2'

snip 05-case-4
run 'cd ../case-4'
run 'cat .git/CHERRY_PICK_HEAD'
run 'cat .git/sequencer/head'
run 'cat .git/sequencer/todo'
run 'git status | head -2'

snip 06-case-5
run 'cd ../case-5'
run 'cat .git/rebase-merge/head-name'
run 'cat .git/rebase-merge/onto .git/rebase-merge/orig-head'
run 'cat .git/rebase-merge/done'
run 'cat .git/rebase-merge/git-rebase-todo'
run 'cat .git/REBASE_HEAD'
run 'git status | head -2'

snip 07-failure
run 'cd ../case-3'
note 'Advice found in an old forum post: "delete the MERGE files and the merge is gone".'
run 'rm .git/MERGE_HEAD .git/MERGE_MODE .git/MERGE_MSG'
run 'git status'
run_rc 'git merge --abort'

snip 08-failure-commit
run "printf 'threshold: 0.80\nmax_tokens: 128\n' > guard.yaml"
run 'git add guard.yaml'
run 'git commit -m "Merge strict guard"'
run 'git log --graph --oneline -4'
run 'git cat-file -p HEAD | grep -c "^parent"'
run 'git branch --no-merged'

snip 09-recovery
run 'git branch rescue/one-parent-merge'
run 'git reset --keep HEAD~1'
run_rc 'git merge feature/strict-guard'
run 'git status | head -2'
run 'git restore --source=rescue/one-parent-merge -- guard.yaml'
run 'git add guard.yaml'
run 'git -c core.editor=true commit'

snip 10-verification
run 'git log --graph --oneline -5'
run 'git cat-file -p HEAD | grep -c "^parent"'
run 'git branch --no-merged'
run 'git diff --stat rescue/one-parent-merge HEAD'
run 'git branch -D rescue/one-parent-merge'
run 'ls .git | grep -c MERGE'

lab_end
