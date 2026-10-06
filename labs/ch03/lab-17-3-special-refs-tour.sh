#!/usr/bin/env bash
# Lab 17.3 replay: a tour of every special ref and state file under .git.
# Each operation is started, inspected and aborted, so the repository ends where it began.
# Then the failure scenario: MERGE_HEAD deleted in the middle of a merge, and the repair of
# the resulting single-parent commit with plumbing.
# No commit ID is hardcoded: the repaired commit is captured in a shell variable, as the learner
# does by hand.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 lab-17-3-special-refs-tour
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-17-3-special-refs.sh" || exit 1

snip 01-baseline
run 'git log --graph --oneline --all'
run 'ls -A .git'

snip 02-fetch-and-reset
run 'git fetch origin'
run 'cat .git/FETCH_HEAD'
note 'A command that moves HEAD "in a drastic way" saves the old position first:'
run 'git reset --soft HEAD~1'
run 'cat .git/ORIG_HEAD'
run 'git reset --soft ORIG_HEAD'
run 'git log --oneline -1'

snip 03-merge
run_rc 'git merge feature/timeouts'
run 'ls -A .git'
run 'cat .git/MERGE_HEAD'
run 'cat .git/MERGE_MSG'
run 'git cat-file -t AUTO_MERGE'

snip 04-root-refs
note 'Root refs are listed. The two pseudorefs, FETCH_HEAD and MERGE_HEAD, are not:'
run 'git for-each-ref --include-root-refs'
note 'Pseudorefs can be read like refs, but update-ref refuses to write them:'
run 'git rev-parse MERGE_HEAD FETCH_HEAD'
run_rc 'git update-ref MERGE_HEAD HEAD'
run_rc 'git update-ref FETCH_HEAD HEAD'
run 'git merge --abort'
run 'ls -A .git'

snip 05-cherry-pick
run_rc 'git cherry-pick feature/timeouts'
run 'ls -A .git'
run 'cat .git/CHERRY_PICK_HEAD'
run 'git cherry-pick --abort'

snip 06-revert
run 'git revert --no-commit HEAD~1'
run 'ls -A .git'
run 'cat .git/REVERT_HEAD'
run 'git revert --abort'

snip 07-rebase
run 'git switch --quiet feature/timeouts'
run_rc 'git rebase main'

snip 08-rebase-state
run 'ls -A .git'
run 'cat .git/REBASE_HEAD'
note 'During a rebase HEAD is detached. The branch being rebased is remembered in the state directory:'
run 'cat .git/HEAD'
run 'cat .git/rebase-merge/head-name'
run 'cat .git/rebase-merge/onto'
run 'git rebase --abort'
run 'git switch --quiet main'

snip 09-bisect-and-stash
run 'git bisect start HEAD HEAD~2'
run 'ls -A .git'
run 'git for-each-ref refs/bisect'
run 'git bisect reset'
run "printf 'retry_limit = 4\\ntimeout_s = 45\\n' > config.toml"
run 'git stash push --quiet -m "try four retries"'
run 'git for-each-ref refs/stash'
run 'cat .git/logs/refs/stash'
run 'git stash pop --quiet'
run 'git restore config.toml'

snip 10-checkpoint
note 'No operation is in progress. Three leftovers remain: FETCH_HEAD, ORIG_HEAD, and AUTO_MERGE,'
note 'the tree that "git stash pop" merged. None of them describes unfinished work.'
run 'git status --short --branch'
run 'git stash list'
run 'ls -A .git'

snip 11-failure
note 'Failure scenario: a merge is resolved, and then MERGE_HEAD is deleted by hand.'
run 'git merge feature/timeouts > /dev/null'
run "printf 'retry_limit = 3\\ntimeout_s = 60\\n' > config.toml"
run 'git add config.toml'
run 'git status | grep merg'
run 'rm .git/MERGE_HEAD'
note 'Git no longer knows that a merge is in progress. The same question now finds nothing:'
run 'git status | grep merg'
run_rc 'git merge --continue'
run 'git commit --quiet -m "Merge branch '"'"'feature/timeouts'"'"'"'
run 'git log --graph --oneline --all'
run 'git branch --no-merged main'

snip 12-recovery
note 'The content is right; the commit lacks its second parent. Build the commit it should have been:'
run 'git cat-file -p HEAD'
run 'fixed=$(git commit-tree -p HEAD~1 -p feature/timeouts -m "Merge branch '"'"'feature/timeouts'"'"'" "HEAD^{tree}")'
run 'echo $fixed'
note 'Nothing points at the new commit yet. Move the branch to it; index and working tree stay as they are:'
run 'git reset --soft $fixed'
run 'git log --graph --oneline --all'

snip 13-verification
run 'git cat-file -p HEAD'
run 'git branch --no-merged main'
run 'git status --short'
run 'ls -A .git'

lab_end
