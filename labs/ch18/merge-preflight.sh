#!/usr/bin/env bash
# The questions a rule asks about a pull request, answered locally with plain Git before you
# look at the merge box: is the branch up to date, does the test merge conflict, which commits
# would land, are they merges, are they signed, who wrote them, which paths change.
# Chapter 18, section 18.15.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 merge-preflight
scenario_pr

snip 01-fetch
run 'git fetch -q'
run 'git status -sb'

snip 02-up-to-date
note 'Rule: require branches to be up to date. Is the tip of the base an ancestor of the head?'
run_rc 'git merge-base --is-ancestor origin/main HEAD'
note 'Commits only main has (left), commits only the branch has (right):'
run 'git rev-list --left-right --count origin/main...HEAD'

snip 03-conflicts
note 'Mergeability: does the test merge succeed?'
run_rc 'git merge-tree --write-tree --name-only origin/main HEAD'

snip 04-commits
note 'The commits a rule inspects: those the pull request introduces.'
run 'git log --format="%h parents=%p" origin/main..HEAD'
note 'Rule: linear history. Merge commits among them:'
run 'git rev-list --count --merges origin/main..HEAD'

snip 05-signatures
note 'Rule: signed commits. %G? prints N for a commit without a signature:'
run 'git log --format="%h %G? %s" origin/main..HEAD'

snip 06-metadata
note 'Rules on commit metadata (Enterprise): author and committer addresses.'
run 'git log --format="%h author=%ae committer=%ce" origin/main..HEAD'

snip 07-paths
note 'Code owners, required reviewers by path, push rules and path filters all key on changed paths:'
run 'git diff --name-only origin/main...HEAD'

snip 08-bring-up-to-date
note 'Fix for "not up to date", variant 1: merge the base into the branch.'
run 'git merge -q origin/main'
run_rc 'git merge-base --is-ancestor origin/main HEAD'
run 'git rev-list --left-right --count origin/main...HEAD'
run 'git rev-list --count --merges origin/main..HEAD'

lab_end
