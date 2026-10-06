#!/usr/bin/env bash
# Exercise 27.4 (Module 27): a guard for a deploy script that refuses to move a target
# backwards or sideways. refs/deployed/production is the author's bookkeeping for the
# demonstration; GitHub keeps deployments as platform objects, not as refs.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x27-deploy-guard
hidden 'git init repo'
cd repo || exit 1
split_v1; commit_all 'Add fixed-size splitter'
config_v1; commit_all 'Add chunking config'
hidden 'git update-ref refs/deployed/production HEAD'
split_v2; commit_all 'Add overlap parameter'
hidden 'git branch hotfix/config HEAD~1'
split_v3; commit_all 'Reject an overlap that is not smaller than the size'
hidden 'git switch hotfix/config'
config_v2; commit_all 'Double the default chunk size'
hidden 'git switch main'
put guard.sh <<'SH'
#!/bin/sh
# usage: sh guard.sh <candidate commit>
# Exit 0 only if the candidate contains everything that production runs, and more.
deployed=$(git rev-parse --verify --quiet refs/deployed/production^{commit}) || { echo "guard: nothing recorded as deployed"; exit 2; }
candidate=$(git rev-parse --verify --quiet "$1^{commit}") || { echo "guard: unknown commit $1"; exit 2; }
if [ "$candidate" = "$deployed" ]; then
  echo "guard: $1 is what production already runs"; exit 1
fi
if git merge-base --is-ancestor "$candidate" "$deployed"; then
  echo "guard: REFUSED, $1 is older than production; this would roll back:"
  git log --oneline "$candidate..$deployed"; exit 1
fi
if ! git merge-base --is-ancestor "$deployed" "$candidate"; then
  echo "guard: REFUSED, $1 does not contain what production runs; missing:"
  git log --oneline "$candidate..$deployed"; exit 1
fi
echo "guard: ok, this deployment adds:"
git log --oneline "$deployed..$candidate"
SH

snip 01-state
run 'git log --graph --oneline --all --decorate-refs=refs/heads --decorate-refs=refs/deployed'

snip 02-guard
run 'cat guard.sh'

snip 03-forward
run_rc 'sh guard.sh main'
run 'git update-ref refs/deployed/production main'

snip 04-backward
note 'A re-run of an old deployment run carries the old commit:'
run_rc 'sh guard.sh main~1'
run_rc 'sh guard.sh main'

snip 05-sideways
run_rc 'sh guard.sh hotfix/config'

lab_end
