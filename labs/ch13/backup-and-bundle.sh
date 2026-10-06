#!/usr/bin/env bash
# Chapter 13, section 13.14: two cheap habits. A backup ref before a risky operation makes
# recovery a one-line command that needs no reflog. A bundle is a whole repository in one
# file: refs and objects, verifiable, and usable as a remote.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 backup-and-bundle
fx_searchsvc
cd searchsvc || exit 1
quiet 'git switch -c feature/rerank'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs)\n' > rerank.py && git add . && git commit -m 'Add reranker'"
quiet "printf 'rerank_top_n: 20\n' > rerank.yaml && git add . && git commit -m 'Rerank the top 20'"
quiet "printf 'rerank_top_n: 50\n' > rerank.yaml && git commit -am 'fixup! Rerank the top 20'"
quiet 'git tag v0.3.0 main'

snip 01-backup-ref
run 'git log --oneline main..HEAD'
run 'git branch backup/rerank-before-squash'
run 'git rebase -q --autosquash main'
run 'git log --oneline main..HEAD'

snip 02-compare-and-restore
run 'git diff --stat backup/rerank-before-squash HEAD'
run 'git range-diff main backup/rerank-before-squash HEAD'
note 'Had the result been wrong, one command would undo it, with no reflog involved:'
run 'git reset --hard backup/rerank-before-squash'
run 'git log --oneline main..HEAD'

snip 03-bundle-create
run 'git bundle create ../searchsvc-2026-09-07.bundle --all'
run 'git bundle verify ../searchsvc-2026-09-07.bundle'

snip 04-bundle-use
run 'git bundle list-heads ../searchsvc-2026-09-07.bundle'
run 'git clone -q ../searchsvc-2026-09-07.bundle ../restored'
run 'git -C ../restored log --oneline --graph --all'

lab_end
