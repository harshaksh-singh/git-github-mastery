#!/usr/bin/env bash
# Chapter 9, section 9.4: a rebase that stops in the middle, so that the state directory
# (.git/rebase-merge), the detached HEAD, ORIG_HEAD and REBASE_HEAD can be inspected. Ends with --abort.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-internals
fx_rerank_conflict

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-stop
run_rc 'git rebase main'

snip 03-head
run 'cat .git/HEAD'
run 'git branch'
run 'git log --oneline --decorate -3'

snip 04-state-dir
run 'ls .git/rebase-merge'

snip 05-state-files
run 'cat .git/rebase-merge/head-name'
run 'cat .git/rebase-merge/orig-head'
run 'cat .git/rebase-merge/onto'
run 'cat .git/rebase-merge/done'
run 'cat .git/rebase-merge/git-rebase-todo'
run 'cat .git/rebase-merge/msgnum .git/rebase-merge/end'
run 'cat .git/rebase-merge/author-script'

snip 06-special-refs
run 'git rev-parse --short ORIG_HEAD'
run 'git rev-parse --short REBASE_HEAD'
run 'git rev-parse --short feat/rerank'
run 'git rev-parse --short HEAD'

snip 07-status
run 'git status'

snip 08-abort
run 'git rebase --abort'
run 'git status'
run 'git reflog -3'
lab_end
