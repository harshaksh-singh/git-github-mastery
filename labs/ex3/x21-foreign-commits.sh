#!/usr/bin/env bash
# Exercise 21.6 (Module 21), model solution: a pull request that lists five commits for a
# two-commit fix, because the branch was cut from a colleague's branch that has since been
# rewritten. The hands-on twin is setup-x21-6-foreign-commits.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x21-foreign-commits
scenario_x21_foreign

snip 01-evidence
run 'git status -sb'
run 'git fetch'
run "git log --format='%h %an: %s' origin/main..HEAD"
run 'git diff --stat origin/main...HEAD'

snip 02-whose
run 'git merge-base origin/main HEAD'
run "git log --format='%h %an: %s' origin/main..origin/feature/semantic-split"
run 'git cherry -v origin/feature/semantic-split HEAD'

snip 03-repair
run "git log --format='%h %an: %s' --author='Lab User' origin/main..HEAD"
run 'git rebase --onto origin/main HEAD~2'
run "git log --format='%h %an: %s' origin/main..HEAD"
run 'git diff --stat origin/main...HEAD'

snip 04-publish
run_rc 'git merge-tree --write-tree --name-only origin/main HEAD'
run 'git push --force-with-lease'
run 'git status -sb'

lab_end
