#!/usr/bin/env bash
# What a pull request shows, computed with plain Git: the commit list is base..head, the diff is
# the three-dot diff base...head, and both are anchored at the merge base.
# Chapter 17, section 17.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 pr-anatomy
scenario_pr

snip 01-two-branches
run 'git fetch'
run 'git log --oneline --graph origin/main feature/priority-routing'

snip 02-commit-list
note 'The "Commits" tab: commits reachable from the head branch and not from the base branch.'
run 'git log --oneline origin/main..feature/priority-routing'
run 'git rev-list --count origin/main..feature/priority-routing'

snip 03-merge-base
run 'git merge-base origin/main feature/priority-routing'
run 'git log --oneline -1 $(git merge-base origin/main feature/priority-routing)'

snip 04-three-dot
note 'The "Files changed" tab: merge base compared with the head. Three dots.'
run 'git diff --stat origin/main...feature/priority-routing'

snip 05-two-dot
note 'Two dots compare the two tips. The newer commit on main appears, reversed.'
run 'git diff --stat origin/main..feature/priority-routing'
run 'git diff origin/main..feature/priority-routing -- config/routing.yaml'

snip 06-equivalence
note 'A three-dot diff is a two-dot diff whose left side is the merge base.'
run 'git diff --stat $(git merge-base origin/main feature/priority-routing) feature/priority-routing'

snip 07-merge-main-in
note 'After the base branch is merged into the head branch, the tip of main is the merge base.'
run 'git merge -q origin/main'
run 'git log --oneline -1 $(git merge-base origin/main feature/priority-routing)'
run 'git diff --stat origin/main..feature/priority-routing'
run 'git diff --stat origin/main...feature/priority-routing'
run 'git log --oneline origin/main..feature/priority-routing'

lab_end
