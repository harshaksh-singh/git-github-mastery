#!/usr/bin/env bash
# Chapter 9, section 9.5, --onto case 2: a fix was cut from main but must ship from the release branch.
# <upstream> only marks where the commits to move begin; --onto names the new base, which may be older.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 onto-sideways
fx_fix_on_main

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-onto
run 'git rebase --onto release/1.4 main fix/timeout'
run 'git log --oneline --graph --decorate --all'

snip 03-check
run 'git diff --stat release/1.4 fix/timeout'
run 'ls app'
lab_end
