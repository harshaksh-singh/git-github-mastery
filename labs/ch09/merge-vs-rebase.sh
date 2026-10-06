#!/usr/bin/env bash
# Chapter 9, section 9.18: the same integration done twice, once with a merge and once with a rebase.
# The final content is identical. What differs is the history: which commits exist, which snapshots
# are new (and therefore untested), and what "git log --first-parent" shows.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 merge-vs-rebase
fx_rerank_clean

snip 01-merge
run 'git switch -c demo/merged main'
run 'git merge feat/rerank'
run 'git log --oneline --graph --decorate demo/merged'

snip 02-rebase
run 'git switch -c demo/rebased feat/rerank'
run 'git rebase main'
run 'git log --oneline --graph --decorate demo/rebased'

snip 03-same-content
run 'git rev-parse "demo/merged^{tree}" "demo/rebased^{tree}"'
run 'git diff --stat demo/merged demo/rebased'

snip 04-snapshots
note 'Commit, tree and subject of everything that is new relative to main, for each result:'
run 'git log --format="%h tree %t  %s" main..demo/merged'
run 'git log --format="%h tree %t  %s" main..demo/rebased'

snip 05-first-parent
run 'git log --oneline --first-parent main..demo/merged'
run 'git log --oneline --first-parent main..demo/rebased'

snip 06-who-contains-the-originals
run 'git branch --contains feat/rerank'
run 'git log --format="%h authored %ad, committed %cd  %s" --date=format:%H:%M main..demo/rebased'
lab_end
