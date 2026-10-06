#!/usr/bin/env bash
# Lab 9.2 replay: a fix branch was cut from a colleague's unmerged experiment. Move only your own
# commits onto main with --onto, then see what the plain form does and repair it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-2-transplant-onto
fx_wrong_base

snip 01-start
run 'git log --graph --decorate --all --format="%h %an: %s%d"'

snip 02-which-commits
run 'git log --oneline main..fix/empty-query'
run 'git log --oneline exp/hybrid-search..fix/empty-query'

snip 03-onto
run 'git rebase --onto main exp/hybrid-search fix/empty-query'

snip 04-result
run 'git log --oneline --graph --decorate --all'
run 'git diff --stat main...fix/empty-query'

snip 05-failure
run 'git reset --hard ORIG_HEAD'
note 'The tempting short form. It replays everything that is not on main, the experiment included.'
run 'git rebase main'
run 'git log --oneline --graph --decorate --all'

snip 06-diagnose
run 'git log --format="%h author %an, committer %cn: %s" main..HEAD'
run 'git diff --stat main...HEAD'

snip 07-recovery
note 'No need to go back first: name the range by counting. HEAD~2 is the last commit that is not yours.'
run 'git rebase --onto main HEAD~2'
run 'git log --oneline --graph --decorate --all'

snip 08-verification
run 'git log --format="%h %an: %s" main..fix/empty-query'
run 'git diff --stat main...fix/empty-query'
run 'git status --short --branch'
lab_end
