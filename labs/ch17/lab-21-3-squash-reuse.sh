#!/usr/bin/env bash
# Lab 21.3 replay: the squash-then-reuse-the-branch problem. Pull request 1 was squash-merged,
# you keep working on its branch, and pull request 2 lists four commits and conflicts.
# Lab manual: lab-manual/m21-pull-requests-forks.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 lab-21-3-squash-reuse
scenario_squash_reuse
cd "$LAB_DIR" || exit 1

snip 01-observe
run 'cd you/ticket-router'
run 'git status -sb'
run 'git log --oneline --graph origin/main feature/priority-routing'

snip 02-follow-up
run "printf '\n\ndef is_urgent(ticket):\n    return priority(ticket) == \"high\"\n' >> router/priority.py"
run 'git commit -am "Add is_urgent helper"'
run 'git push'

snip 03-pr2-view
run 'git log --oneline origin/main..feature/priority-routing'
run 'git diff --stat origin/main...feature/priority-routing'
run 'git show --stat --format="%h %s" HEAD'

snip 04-pr2-conflict
run_rc 'git merge-tree --write-tree --name-only origin/main feature/priority-routing'
run 'git log --oneline -1 $(git merge-base origin/main feature/priority-routing)'

snip 05-fix
run 'git branch before-fix'
run 'git rebase --onto origin/main HEAD~1'
run 'git log --oneline origin/main..feature/priority-routing'
run 'git diff --stat origin/main...feature/priority-routing'
run_rc 'git merge-tree --write-tree origin/main feature/priority-routing'
run 'git push --force-with-lease'

snip 06-checkpoint
run 'git log --oneline --graph -3'
run 'git log --oneline -1 $(git merge-base origin/main feature/priority-routing)'

snip 07-failure
note 'What a plain rebase onto main does with the same branch:'
run 'git switch -c try/plain-rebase before-fix'
run_rc 'git rebase origin/main'
run 'git status'

snip 08-recovery
run 'git rebase --abort'
run 'git status -sb'
run 'git switch -q feature/priority-routing'
run 'git branch -D try/plain-rebase before-fix'

snip 09-verification
run 'git rev-list --count origin/main..feature/priority-routing'
run 'git cherry -v origin/main feature/priority-routing'
run 'git status -sb'

lab_end
