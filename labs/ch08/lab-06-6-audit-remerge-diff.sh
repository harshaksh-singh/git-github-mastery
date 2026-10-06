#!/usr/bin/env bash
# Lab 6.6 replay: audit four merges on main with --remerge-diff, then meet its octopus blind spot.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
lab_begin ch08 lab-06-6-audit-remerge-diff

quiet 'm06_6_fixture'

snip 01-merges
run 'git log --merges --format="%h %<(10)%an %s"'
note 'git log -p prints no diff for any of them:'
run 'git log --merges -p --format="%h %s"'

snip 02-remerge-diff
run 'git log --merges --remerge-diff --format="== %h %an: %s"'

M3=$(git log --merges -1 --format=%h --grep=creative-judge)
snip 03-lost-work
note 'Who wrote the line that the creative-judge merge removed, and what did the merge do to it?'
run "git log --format='%h %an: %s' -S'retries: 3' --full-history -- config/eval.yaml"
run "git diff -U0 $M3^1 $M3 -- config/eval.yaml"

snip 04-hidden-from-log
note 'A path-limited log follows only the parent whose file the merge kept:'
run 'git log --oneline -- config/eval.yaml'
run 'git log --oneline --full-history -- config/eval.yaml'

# ---- Failure scenario: an octopus merge with a smuggled change.
snip 05-failure
run 'git merge --no-commit docs/contributing docs/changelog'
note 'Before committing, change something that neither branch touches:'
run "sed -e 's/^seed: .*/seed: 99/' config/eval.yaml > c && mv c config/eval.yaml"
run 'git add config/eval.yaml'
run 'git commit -q --no-edit'
run 'git show --remerge-diff --format="%h %s" HEAD'

snip 06-recovery
note 'The combined diff still works for any number of parents:'
run 'git show --format="%h %s" HEAD'

snip 07-recovery-plumbing
note 'Or redo the merge mechanically, two heads at a time, and compare trees:'
run 'step1=$(git merge-tree --write-tree HEAD^1 HEAD^2)'
run 'tmp=$(git commit-tree $step1 -p HEAD^1 -p HEAD^2 -m "temporary: first two heads")'
run 'step2=$(git merge-tree --write-tree $tmp HEAD^3)'
run 'git diff $step2 HEAD'

snip 08-verification
run 'git log -1 --format="%h parents: %p"'
run 'git diff --stat $step2 HEAD'
run 'git status --short --branch'

lab_end
