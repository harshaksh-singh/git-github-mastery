#!/usr/bin/env bash
# Lab 9.6 replay: you rebase and force-push a branch that Asha has also built on. Her clone reports a
# divergence, her merge duplicates every shared commit, and a rebase onto the new upstream repairs it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-6-shared-branch-duplicates
fx_shared_branch

snip 01-you-rebase
run 'git log --oneline --graph --decorate --all'
run 'git rebase main'
run 'git push --force-with-lease --force-if-includes'

snip 02-asha-sees
run 'cd ../asha'
run 'git fetch'
run 'git status --short --branch'
run 'git log --oneline --graph --decorate --all'

snip 03-failure
run 'git pull --no-rebase'
run 'git log --oneline --graph --decorate'

snip 04-diagnose
run 'git log --format=%s origin/main..HEAD | sort | uniq -d'
run 'git cherry -v origin/feat/ingest ORIG_HEAD'

snip 05-recovery
run 'git reset --hard ORIG_HEAD'
run 'git rebase --onto origin/feat/ingest dc5df93'
run 'git log --oneline --graph --decorate'

snip 06-publish
run 'git push'
run 'cd ../you'
run 'git pull --ff-only'

snip 07-verification
run 'git log --oneline --graph --decorate --all'
run 'git log --format=%s origin/main..HEAD | sort | uniq -d'
run 'git -C ../asha rev-parse --short HEAD'
run 'git rev-parse --short HEAD'
lab_end
