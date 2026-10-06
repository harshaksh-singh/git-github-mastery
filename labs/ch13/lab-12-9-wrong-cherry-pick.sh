#!/usr/bin/env bash
# Lab 12.9 replay: the wrong commit (a feature instead of the fix) is cherry-picked onto a
# release branch. Recovery: step back one reflog entry, then pick the right commit. Failure:
# "git reset --hard ORIG_HEAD" after a cherry-pick. Cherry-pick does not write ORIG_HEAD, so
# the file still holds a value from an old merge on another branch. Recovery: the branch reflog.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-9-wrong-cherry-pick
fx_12_9

snip 01-start
run 'cd apigw'
run 'git status -sb'
run 'git log --oneline --graph --all'

snip 02-disaster
note 'The fix to backport is "Fix off-by-one in rate limit window". The newest commit on main is not it.'
run 'git cherry-pick -x main'
run 'git log --oneline -3'
run 'git show --stat --format=%B HEAD'

snip 03-evidence
run 'git reflog -2'
run 'git reflog show release/2.1 -2'

snip 04-recover
run "git reset --keep 'HEAD@{1}'"
run 'git log --oneline -2'
run 'git cherry-pick -x main~1'

snip 05-verification
run 'git log --oneline -3'
run 'git cherry -v release/2.1 main'
run 'ls'

snip 06-failure
run 'cd ../apigw-incident'
run 'git log --oneline -3'
note 'The wrong pick is already here. A recipe remembered from the merge chapter:'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline'
run 'git status -sb'
run 'ls'

snip 07-recovery-read
run 'git reflog show release/2.1'
run 'git reflog -4'

snip 08-recovery
run "git reset --keep 'release/2.1@{2}'"
run 'git log --oneline -2'
run 'git cherry-pick -x main~1'

snip 09-after
run 'git log --oneline --graph --all'
run 'ls'

lab_end
