#!/usr/bin/env bash
# Chapter 9, section 9.13: "git pull --rebase" is "git fetch" followed by a rebase of your unpushed
# commits onto the fetched upstream branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 pull-rebase
fx_diverged_main

snip 01-diverged
run 'git fetch'
run 'git status --short --branch'
run 'git log --oneline --graph --decorate --all'

snip 02-pull-refuses
run_rc 'git pull'

snip 03-pull-rebase
run 'git pull --rebase'
run 'git log --oneline --graph --decorate --all'
run 'git reflog -4'

snip 04-push
run 'git push'

snip 05-config
run 'git config set pull.rebase true'
lab_end
