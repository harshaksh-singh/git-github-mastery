#!/usr/bin/env bash
# Lab 12.4 replay: a hotfix branch cut from release/1.4 was rebased onto main, and one more
# commit was added before anyone noticed. Recovery: anchor the tip from before the rebase and
# transplant the new commit onto it with "git rebase --onto". Failure: a plain reset to the
# old tip loses the new commit. Recovery: ORIG_HEAD, valid because the reset just wrote it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-4-wrong-rebase
fx_12_4

snip 01-symptom
run 'cd evalharness'
run 'git status -sb'
run 'git log --oneline release/1.4..HEAD'
run 'git log --oneline --graph --all'

snip 02-evidence
run 'git reflog show hotfix/judge-timeout'

snip 03-anchor
run "git branch rescue/pre-rebase 'hotfix/judge-timeout@{2}'"
run 'git log --oneline release/1.4..rescue/pre-rebase'
run 'git branch backup/rebased-hotfix'

snip 04-transplant
run 'git rebase --onto rescue/pre-rebase HEAD~1'
run 'git log --oneline release/1.4..HEAD'

snip 05-verification
run 'git log --oneline --graph release/1.4 hotfix/judge-timeout main'
run 'git range-diff backup/rebased-hotfix~1..backup/rebased-hotfix HEAD~1..HEAD'
run 'git diff --stat release/1.4 HEAD'
run 'git branch -D rescue/pre-rebase backup/rebased-hotfix'

snip 06-failure
run 'cd ../evalharness-incident'
run "git reset --hard 'hotfix/judge-timeout@{2}'"
run 'git log --oneline release/1.4..HEAD'
run 'cat runner.py'

snip 07-recovery
run 'git log --oneline -1 ORIG_HEAD'
run 'git reflog show hotfix/judge-timeout -2'
run 'git cherry-pick ORIG_HEAD'

snip 08-after
run 'git log --oneline release/1.4..HEAD'
run 'cat runner.py'

lab_end
