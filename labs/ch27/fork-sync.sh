#!/usr/bin/env bash
# Chapter 27, sections 27.2 and 27.3: the fork workflow from the contributor's side, with two
# bare repositories playing upstream and fork, and the ways to bring the fork and the feature
# branch up to date when upstream moves.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch27 fork-sync
fx_fork

snip 01-clone-fork
note 'fork/promptgate.git plays your fork on the platform. Clone it, then name the upstream:'
run 'git clone -q fork/promptgate.git you/promptgate'
run 'cd you/promptgate'
quiet 'git remote set-url origin ../../fork/promptgate.git'
run 'git remote add upstream ../../upstream/promptgate.git'
run 'git fetch -q upstream'
run 'git remote -v'
run 'git branch -a -vv'

snip 02-branch-commit-push
run 'git switch -c fix/suspended-tenant upstream/main'
limits_fixed
run 'git commit -q -am "Fix limit 0 being treated as unlimited"'
run 'git push -u origin fix/suspended-tenant'

asha_lands stream 'Stream tokens to the client'

snip 03-upstream-moved
note 'While your pull request waits for review, the maintainer merges other work:'
run 'git fetch upstream'
run 'git rev-list --left-right --count upstream/main...origin/main'
run 'git log --oneline --graph --all'

snip 04-sync-main
note 'Bring the main branch of the fork up to date. Your local main is only a relay:'
run 'git switch -q main'
run 'git merge --ff-only upstream/main'
run 'git push origin main'
run 'git rev-list --left-right --count upstream/main...origin/main'

snip 05-update-by-rebase
note 'Update the feature branch, way 1: replay it on the new upstream tip.'
run 'git switch -q fix/suspended-tenant'
run 'git rebase upstream/main'
run_rc 'git push'
run 'git push --force-with-lease --force-if-includes'
run 'git log --oneline --graph --all'

asha_lands fallback 'Fall back to a second model on timeout'

snip 06-update-by-merge
note 'Upstream moved again. Way 2: merge upstream into the branch. No commit is rewritten,'
note 'so a plain push is enough:'
run 'git fetch -q upstream'
run 'git merge -m "Merge upstream main into fix/suspended-tenant" upstream/main'
run 'git push'
run 'git log --oneline --graph fix/suspended-tenant'

snip 07-review-round
note 'The reviewer asks for a test. Changes after review start are added, not rewritten:'
run "mkdir -p tests && printf 'from gateway.limits import LIMITS, allowed\n\n\ndef test_suspended():\n    LIMITS[\"acme\"] = 0\n    assert not allowed(\"acme\", 0)\n' > tests/test_limits.py"
run 'git add tests && git commit -q -m "Test that a limit of 0 blocks the tenant"'
run 'git push'
run 'git log --oneline upstream/main..HEAD'

tip=$(git rev-parse HEAD)
( cd "$LAB_DIR/asha/promptgate" || exit 1
  as asha
  hidden 'git pull -q --ff-only'
  hidden 'git fetch ../../fork/promptgate.git fix/suspended-tenant'
  hidden 'git merge --squash FETCH_HEAD'
  hidden 'git commit -m "Fix limit 0 being treated as unlimited (#57)"'
  hidden 'git push origin main' ) || exit 1
tick; tick; tick; tick; tick

snip 08-after-squash-merge
note 'The maintainer squash-merges the pull request. Upstream main has one new commit:'
run 'git fetch upstream'
run 'git log --oneline -2 upstream/main'
run 'git switch -q main && git merge -q --ff-only upstream/main && git push -q origin main'
note 'Your commits are not ancestors of main: the squash made one new commit with a new ID.'
run_rc 'git merge-base --is-ancestor fix/suspended-tenant main'
note 'Compare content instead. No output means main has everything the branch has:'
run 'git diff --stat main fix/suspended-tenant'
run 'git branch -d fix/suspended-tenant'
run 'git push origin --delete fix/suspended-tenant'
lab_end
