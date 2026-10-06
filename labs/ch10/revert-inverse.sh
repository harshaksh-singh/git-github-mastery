#!/usr/bin/env bash
# Chapter 10, section 10.11: revert is the same three-way merge with base and "theirs" exchanged:
# the base is the commit itself and "theirs" is its parent.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 revert-inverse
fx_gateway_fix
quiet 'git cherry-pick -x main~1'

snip 01-before
run 'git log --oneline --decorate -3'
run 'git rev-parse HEAD~1^{tree}'

snip 02-predict
note 'Base: the commit to undo (HEAD). Ours: HEAD. Theirs: the parent of the commit to undo.'
run 'git merge-tree --write-tree --merge-base=HEAD HEAD HEAD~1'

snip 03-revert
run 'git revert --no-edit HEAD'
run 'git rev-parse HEAD^{tree}'
run 'git log -1 --format=%B'

snip 04-after
run 'git log --oneline --decorate -4'
lab_end
