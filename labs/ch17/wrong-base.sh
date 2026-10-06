#!/usr/bin/env bash
# A pull request opened against the wrong base: the commit list and the diff contain every
# commit of the branch the work was really based on. Diagnosis with ranges, and the two fixes:
# change the base, or transplant the branch with git rebase --onto. Chapter 17, section 17.12.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 wrong-base
scenario_wrong_base

snip 01-situation
note 'Ravi. One commit of his own, on a branch he created from main:'
run 'git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject'

snip 02-pr-against-release
note 'The pull request was opened with base release/1.0. What it lists and shows:'
run 'git log --oneline origin/release/1.0..fix/empty-subject'
run 'git diff --stat origin/release/1.0...fix/empty-subject'

snip 03-diagnose
note 'Which base makes this branch a one-commit pull request?'
run 'for b in origin/main origin/release/1.0; do echo "$b: $(git rev-list --count $b..fix/empty-subject) commits"; done'
run 'git log --oneline -1 $(git merge-base origin/release/1.0 fix/empty-subject)'
run 'git log --oneline -1 $(git merge-base origin/main fix/empty-subject)'

snip 04-fix-a-change-base
note 'Fix A: the change belongs on main after all. Same branch, other base:'
run 'git log --oneline origin/main..fix/empty-subject'
run 'git diff --stat origin/main...fix/empty-subject'

snip 05-fix-b-transplant
note 'Fix B: the change does belong on release/1.0. Move the one commit there:'
run 'git rebase --onto origin/release/1.0 origin/main fix/empty-subject'
run 'git log --oneline origin/release/1.0..fix/empty-subject'
run 'git diff --stat origin/release/1.0...fix/empty-subject'
run 'git log --oneline --graph origin/main origin/release/1.0 fix/empty-subject'

snip 06-republish
run_rc 'git push'
run 'git push --force-with-lease'

lab_end
