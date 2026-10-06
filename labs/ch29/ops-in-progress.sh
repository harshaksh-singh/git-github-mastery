#!/usr/bin/env bash
# Chapter 29, section 29.6: how git status and the files in .git reveal an operation in
# progress. One repository per operation: merge, rebase, cherry-pick, revert, bisect. Each is
# stopped half-way and inspected, then ended with its own abort command.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 ops-in-progress
fx_ops_base clean
fx_op merging merge
fx_op rebasing rebase
fx_op picking cherry-pick
fx_op reverting revert
fx_op bisecting bisect

snip 01-clean
run 'cd clean'
run 'git log --graph --oneline --all'
run 'git status'
run 'ls .git'
run 'cat .git/HEAD'

snip 02-merge-status
run 'cd ../merging'
run 'git status'

snip 03-merge-files
run 'ls .git'
run 'cat .git/MERGE_HEAD'
run 'cat .git/MERGE_MODE'
run 'cat .git/MERGE_MSG'
run 'cat .git/ORIG_HEAD'
run 'git ls-files -u'

snip 04-rebase-status
run 'cd ../rebasing'
run 'git status'

snip 05-rebase-files
run 'ls .git'
run 'cat .git/HEAD'
run 'cat .git/REBASE_HEAD'
run 'cat .git/rebase-merge/head-name'
run 'cat .git/rebase-merge/onto'
run 'cat .git/rebase-merge/orig-head'
run 'cat .git/rebase-merge/msgnum .git/rebase-merge/end'
run 'cat .git/rebase-merge/git-rebase-todo'

snip 06-pick-status
run 'cd ../picking'
run 'git status'

snip 07-pick-files
run 'ls .git'
run 'cat .git/CHERRY_PICK_HEAD'
run 'ls .git/sequencer'
run 'cat .git/sequencer/head'
run 'cat .git/sequencer/todo'

snip 08-revert-status
run 'cd ../reverting'
run 'git status'

snip 09-revert-files
run 'ls .git'
run 'cat .git/REVERT_HEAD'
run 'cat .git/MERGE_MSG'

snip 10-bisect-status
run 'cd ../bisecting'
run 'git status'

snip 11-bisect-files
run 'ls .git'
run 'cat .git/HEAD'
run 'cat .git/BISECT_START'
run 'cat .git/BISECT_TERMS'
run 'cat .git/BISECT_LOG'
run 'git for-each-ref refs/bisect'

snip 12-one-question
note 'One read-only question for any repository: which state files exist?'
run 'for d in clean merging rebasing picking reverting bisecting; do echo "== $d"; ls ../$d/.git | grep -E "_HEAD$|rebase-|sequencer|BISECT_LOG"; done'

snip 13-refusals
run 'cd ../merging'
run_rc 'git switch feature/strict-guard'
run_rc 'git cherry-pick feature/strict-guard~1'
run_rc 'git merge feature/strict-guard'
run 'cd ../rebasing'
run_rc 'git rebase main'

snip 14-ways-out
run 'cd ../merging && git merge --abort && git status -sb && ls .git | grep -c MERGE'
run 'cd ../rebasing && git rebase --abort && git status -sb'
run 'cd ../picking && git cherry-pick --abort && git status -sb'
run 'cd ../reverting && git revert --abort && git status -sb'
run 'cd ../bisecting && git bisect reset && git status -sb'

lab_end
