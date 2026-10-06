#!/usr/bin/env bash
# Chapter 10, section 10.10: the same change exists on two branches under two commit IDs. How
# "git cherry" and "git log --cherry-mark" find such pairs through patch IDs, and what happens when
# the two branches are later merged.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 duplicates
fx_gateway_fix timeout
quiet 'git cherry-pick -x main~1'

snip 01-graph
run 'git log --oneline --graph --decorate --all'

snip 02-cherry
run 'git cherry -v release/1.4 main'
run 'git cherry -v main release/1.4'

snip 03-cherry-mark
run 'git log --oneline --left-right --cherry-mark release/1.4...main'

snip 04-cherry-pick
run 'git log --oneline --left-right --cherry-pick release/1.4...main'

snip 05-patch-id
run 'git show main~1 | git patch-id --stable'
run 'git show release/1.4 | git patch-id --stable'

snip 06-merge
run 'git switch main'
run 'git merge -m "Merge branch release/1.4 into main" release/1.4'
run 'git log --oneline --graph --decorate -7'

snip 07-twice-in-history
run 'git log --oneline --grep="Reject empty prompts"'
lab_end
