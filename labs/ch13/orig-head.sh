#!/usr/bin/env bash
# Chapter 13, section 13.5: which commands write ORIG_HEAD and which do not. One command per
# step, and after each one the question "what does ORIG_HEAD say now?".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 orig-head
fx_searchsvc
cd searchsvc || exit 1
quiet 'git switch -c feature/rerank'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs)\n' > rerank.py && git add . && git commit -m 'Add reranker'"
quiet "printf 'rerank_top_n: 20\n' > rerank.yaml && git add . && git commit -m 'Rerank the top 20'"
quiet 'git switch main'
quiet "printf '# searchsvc\n' > README.md && git add . && git commit -m 'Add README'"

snip 01-not-written
run 'git log --oneline --graph --all'
note 'A fresh repository has no ORIG_HEAD. These four commands move HEAD and do not create it:'
run 'git commit -q --amend -m "Add a README"'
run 'git switch -q feature/rerank && git switch -q main'
run 'git cherry-pick feature/rerank~1 > /dev/null'
run 'git revert --no-edit HEAD > /dev/null'
run_rc 'git rev-parse --verify --short ORIG_HEAD'
run 'git reflog -4'

snip 02-reset
run 'git reset -q --hard HEAD~2'
run 'git log --oneline -1 ORIG_HEAD'

snip 03-merge
run 'git log --oneline -1'
run 'git merge -q feature/rerank'
run 'git log --oneline -1 ORIG_HEAD'

snip 04-rebase
run 'git reset -q --hard ORIG_HEAD'
run 'git switch -q feature/rerank'
run 'git log --oneline -1'
run 'git rebase -q main'
run 'git log --oneline -1 ORIG_HEAD'

snip 05-stale
note 'A later command that does not write ORIG_HEAD leaves the old value in place:'
run 'git switch -q main'
run 'git cherry-pick feature/rerank > /dev/null'
run 'git log --oneline -1 ORIG_HEAD'
run 'git branch --contains ORIG_HEAD'
run 'cat .git/ORIG_HEAD'
run_rc 'git reflog exists ORIG_HEAD'

lab_end
