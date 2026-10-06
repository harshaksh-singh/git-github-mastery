#!/usr/bin/env bash
# Chapter 9, section 9.8: where the autostash is while a rebase is stopped at a conflict, and what
# --abort and --quit do with it. The uncommitted change is one line in config/model.yaml.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 autostash-stopped
fx_rerank_conflict
printf 'top_p: 0.9\n' >> config/model.yaml

snip 01-stopped
run 'git status --short'
run_rc 'git rebase --autostash main'

snip 02-where-is-it
run 'git status --short'
run 'git stash list'
run 'cat .git/rebase-merge/autostash'
run 'git stash show -p $(cat .git/rebase-merge/autostash)'

snip 03-abort
run 'git rebase --abort'
run 'git status --short'

snip 04-quit
quiet 'git rebase --autostash main'
note 'The same stop again. This time the rebase is left with --quit.'
run 'git rebase --quit'
run 'git stash list'
run 'git status --short'
lab_end
