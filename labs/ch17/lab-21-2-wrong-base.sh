#!/usr/bin/env bash
# Lab 21.2 replay: a pull request against the wrong base. Predict what it lists, find the base
# that fits, transplant the branch with git rebase --onto, and see why a plain rebase does not
# repair it. Lab manual: lab-manual/m21-pull-requests-forks.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 lab-21-2-wrong-base
scenario_wrong_base you
cd "$LAB_DIR" || exit 1

snip 01-observe
run 'cd you/ticket-router'
run 'git status -sb'
run 'git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject'

snip 02-pr-view
run 'git log --oneline origin/release/1.0..fix/empty-subject'
run 'git diff --stat origin/release/1.0...fix/empty-subject'

snip 03-diagnose
run 'for b in origin/main origin/release/1.0; do echo "$b: $(git rev-list --count $b..fix/empty-subject) commits"; done'
run 'git log --oneline -1 $(git merge-base origin/release/1.0 fix/empty-subject)'
run 'git log --oneline -1 $(git merge-base origin/main fix/empty-subject)'

snip 04-transplant
run 'git branch backup/fix-empty-subject'
run 'git rebase --onto origin/release/1.0 origin/main fix/empty-subject'
run 'git log --oneline origin/release/1.0..fix/empty-subject'
run 'git diff --stat origin/release/1.0...fix/empty-subject'

snip 05-republish
run_rc 'git push'
run 'git push --force-with-lease'

snip 06-checkpoint
run 'git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject'

snip 07-failure
note 'The repair that sounds right and is not: a plain rebase onto the base branch.'
run 'git switch -c try/plain-rebase backup/fix-empty-subject'
run 'git rebase origin/release/1.0'
run 'git log --oneline origin/release/1.0..try/plain-rebase'
run 'git diff --stat origin/release/1.0...try/plain-rebase'

snip 08-recovery
run 'git reflog -4 try/plain-rebase'
run 'git rebase --onto origin/release/1.0 HEAD~1'
run 'git log --oneline origin/release/1.0..try/plain-rebase'

snip 09-verification
note 'Both branches now hold the same tree, one commit on top of release/1.0:'
run 'git rev-parse fix/empty-subject^{tree} try/plain-rebase^{tree}'
run 'git rev-list --count origin/release/1.0..fix/empty-subject'
run 'git switch -q fix/empty-subject'
run 'git branch -D try/plain-rebase backup/fix-empty-subject'
run 'git status -sb'

lab_end
