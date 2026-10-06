#!/usr/bin/env bash
# The squash-then-reuse-the-branch problem as a pull request shows it: commits that were already
# squashed into the base are listed again, the diff repeats them, and the test merge conflicts.
# Then the three ways out. Chapter 17, section 17.12.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 squash-reuse
scenario_squash_reuse

snip 01-after-squash
note 'Pull request 1 was squash-merged. Its branch was not deleted.'
run 'git log --oneline --graph origin/main feature/priority-routing'

snip 02-keep-working
note 'You keep working on the same branch: one small follow-up commit.'
priority_v2
run 'git diff --stat'
run 'git commit -q -am "Treat data loss as urgent"'
run 'git push -q'

snip 03-pr2-commits
note 'Pull request 2, same head branch, same base. Its commit list:'
run 'git log --oneline origin/main..feature/priority-routing'
note 'Its diff (three dots), and what you believe you changed (your last commit):'
run 'git diff --stat origin/main...feature/priority-routing'
run 'git show --stat --format="%h %s" HEAD'

snip 04-pr2-test-merge
note 'The test merge of pull request 2:'
run_rc 'git merge-tree --write-tree --name-only origin/main feature/priority-routing'

snip 05-why
run 'git log --oneline -1 $(git merge-base origin/main feature/priority-routing)'
run 'git show -s --format="%h parents: %p  %s" origin/main'

cd "$LAB_DIR" || exit 1
cp -R you you-merge
cp -R you you-plain-rebase
cd you/ticket-router || exit 1

snip 06-fix-rebase-onto
note 'Way out 1: move only the new commit onto main. Everything up to HEAD~1 is already there.'
run 'git rebase --onto origin/main HEAD~1'
run 'git log --oneline origin/main..feature/priority-routing'
run 'git diff --stat origin/main...feature/priority-routing'
run_rc 'git merge-tree --write-tree origin/main feature/priority-routing'
run 'git push --force-with-lease'

snip 07-plain-rebase
note 'In a copy of the clone: a plain rebase replays all four commits.'
run 'cd ../../you-plain-rebase/ticket-router'
run_rc 'git rebase origin/main'
run 'git status --short'
run 'git rebase --abort'

snip 08-merge-main
note 'In another copy. Way out 2: merge main into the branch and resolve once.'
run 'cd ../../you-merge/ticket-router'
run_rc 'git merge origin/main'
note 'The branch has everything main has plus the new word, so the branch side is the answer:'
run 'git restore --ours router/priority.py'
run 'git add router/priority.py'
run 'git commit -q -m "Merge main into feature/priority-routing"'
run 'git log --oneline -1 $(git merge-base origin/main feature/priority-routing)'
run 'git diff --stat origin/main...feature/priority-routing'
run 'git log --oneline origin/main..feature/priority-routing'

snip 09-prevention
note 'Way out 3, the one that prevents the problem: a new branch from main for new work.'
run 'cd ../../you/ticket-router'
run 'git switch -q -c feature/audit-log origin/main'
run 'git log --oneline origin/main..feature/audit-log'
run 'git rev-list --count origin/main..feature/audit-log'

lab_end
