#!/usr/bin/env bash
# Chapter 9, section 9.9: stacked branches. Without --update-refs only the checked-out branch moves and
# the branches below it are left on the old commits; with --update-refs they move too.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 update-refs
fx_ingest_stack

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-without
run 'git rebase main'
run 'git log --oneline --graph --decorate --all'

snip 03-undo
run 'git reset --hard ORIG_HEAD'

snip 04-with
run_todo '' 'git rebase -i --update-refs main'

snip 05-after
run 'git log --oneline --graph --decorate --all'
run 'git reflog show feat/ingest-loader -2'

snip 06-backup-trap
note 'A "backup" branch that points into the range is a branch like any other:'
quiet 'git switch main'
put LICENSE <<'TXTEOF'
Apache-2.0
TXTEOF
commit_all "Add licence"
quiet 'git switch feat/ingest-chunker'
run 'git branch backup/chunker'
run 'git tag before-rebase'
run 'git rebase --update-refs main'
run 'git log --oneline --decorate -1 backup/chunker'
run 'git log --oneline --decorate -1 before-rebase'

snip 07-config
run 'git config set rebase.updateRefs true'
lab_end
