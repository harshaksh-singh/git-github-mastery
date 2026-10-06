#!/usr/bin/env bash
# Lab 10.4 replay: predict what A..B and A...B select for git log and what they compare for git diff,
# on two diverged branches. The failure scenario applies a two-endpoint diff as "the feature patch"
# and silently reverts two commits of main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/retriever.sh"
lab_begin ch14a lab-10-4-range-notation
fx_retriever || exit 1

snip 01-graph
run 'git log --graph --oneline --all'
run 'cat config.yaml'

snip 02-log-two-dots
run 'git log --oneline main..feat/rerank'
run 'git log --oneline feat/rerank..main'

snip 03-log-three-dots
run 'git log --oneline main...feat/rerank'
run 'git log --oneline --left-right main...feat/rerank'

snip 04-diff-two-dots
run 'git diff --stat main..feat/rerank'
run 'git diff main..feat/rerank -- config.yaml'

snip 05-diff-three-dots
run 'git diff --stat main...feat/rerank'
run 'git diff main...feat/rerank -- config.yaml'

snip 06-merge-base
run 'git merge-base main feat/rerank'
run 'git diff --stat $(git merge-base main feat/rerank) feat/rerank'
run 'git diff --stat feat/rerank...main'

snip 07-after-update
note 'Bring the branch up to date with main, on a copy of the branch, and ask again.'
run 'git switch --quiet -c feat/rerank-updated feat/rerank'
run 'git merge --no-edit main'
run 'git log --oneline main..feat/rerank-updated'
run 'git log --oneline feat/rerank-updated..main'

snip 08-after-update-diff
run 'git diff --stat main..feat/rerank-updated'
run 'git diff --stat main...feat/rerank-updated'
run 'git switch --quiet main'

snip 09-failure
note 'A colleague ships the feature as a patch: "the diff between main and the branch".'
run 'git diff main..feat/rerank | git apply --index'
run 'git commit -q -m "Add reranker (applied as a patch)"'
run 'git show --stat --format="%h %s" HEAD'

snip 10-diagnose
run 'git diff HEAD~1 HEAD -- config.yaml'
run 'git log --oneline -3 -- config.yaml'

snip 11-recovery
note 'The commit is unpushed and the working tree is clean, so the branch can step back one commit.'
run 'git reset --hard HEAD~1'
note 'The three-dot diff is the right patch, but it was made against the merge base, not against main:'
run_rc 'git diff main...feat/rerank | git apply --index'

snip 12-recovery-3way
run 'git diff main...feat/rerank | git apply --3way'
run 'git status --short'
run 'git commit -q -m "Add reranker (applied as a patch)"'

snip 13-verification
run 'git show --stat --format="%h %s" HEAD'
run 'cat config.yaml'
run 'git diff --stat HEAD feat/rerank-updated'
lab_end
