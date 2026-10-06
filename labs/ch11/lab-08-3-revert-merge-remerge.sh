#!/usr/bin/env bash
# Lab 8.3 replay: merge a branch, revert the merge with -m 1, see that re-merging brings
# nothing, fix the branch, then revert the revert and merge again. Failure: merging the fixed
# branch without reverting the revert. Recovery: back to the good state through the reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-3-revert-merge-remerge
fx_08_3

snip 01-merge
run 'cd pipeline'
run 'git log --oneline --graph --all'
run 'git merge feature/dedup'
run 'ls'

snip 02-revert-the-merge
run_rc 'git revert --no-edit HEAD'
run 'git show -s --format="%h parents: %p" HEAD'
run 'git revert --no-edit -m 1 HEAD'
run 'ls'
revert_commit=$(git rev-parse --short HEAD)

snip 03-remerge-brings-nothing
run 'git merge feature/dedup'
run 'git merge-base main feature/dedup'
run 'git rev-parse feature/dedup'

snip 04-fix-on-the-branch
run 'git switch feature/dedup'
run "printf 'columns: [id, text, label]\ndedup_threshold: 0.95\n' > schema.yaml"
run 'git commit -am "Read the duplicate threshold from the schema"'
run 'git switch main'

snip 05-revert-the-revert-then-merge
run "git revert --no-edit $revert_commit"
run 'git merge feature/dedup'
run 'ls'
good=$(git rev-parse --short HEAD)

snip 06-failure
run "git reset --hard $revert_commit"
run 'git merge feature/dedup'
run 'ls'
run 'git grep -n dedup'

snip 07-recovery
run 'git reflog -4'
run "git reset --hard $good"
run 'ls'

snip 08-verification
run 'git log --oneline --graph'
run 'git branch --merged main'
run 'git grep -n dedup -- pipeline.py schema.yaml'

lab_end
