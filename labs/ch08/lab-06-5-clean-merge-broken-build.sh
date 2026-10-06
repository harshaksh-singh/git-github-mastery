#!/usr/bin/env bash
# Lab 6.5 replay: two branches that each pass the check, a merge without conflict, a failing check.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-5-clean-merge-broken-build

quiet 'm06_5_fixture'

snip 01-green-branches
run 'git log --oneline --graph --all'
run 'git switch -q --detach feature/prompt-versions && sh ci/check_migrations.sh'
run 'git switch -q --detach feature/latency && sh ci/check_migrations.sh'
run 'git switch -q main'

snip 02-merges
run 'git merge feature/prompt-versions'
run 'git merge feature/latency'

snip 03-red
run_rc 'sh ci/check_migrations.sh'
run 'git ls-files migrations'

snip 04-diagnosis
note 'What each parent contributed to the merge result:'
run 'git diff --name-status main^1 main'
run 'git diff --name-status main^2 main'
run 'git show --remerge-diff --format="%h %s" main'

# ---- Failure scenario: the repair is folded into the merge commit.
snip 05-failure
run 'git mv migrations/0003_add_latency_ms.sql migrations/0004_add_latency_ms.sql'
run 'git commit -q --amend --no-edit'
run 'sh ci/check_migrations.sh'
run 'git log -1 -p --format="%h %s"'
run 'git show --remerge-diff --format="%h %s" HEAD'

snip 06-recovery
run 'git reflog -2'
run 'git reset --keep HEAD@{1}'
run 'git log --oneline -1'
run 'git mv migrations/0003_add_latency_ms.sql migrations/0004_add_latency_ms.sql'
run 'git commit -q -m "Renumber the latency migration to 0004"'

snip 07-verification
run 'sh ci/check_migrations.sh'
run 'git log --oneline --graph -4'
run 'git show --stat --format="%h %s" HEAD'

lab_end
