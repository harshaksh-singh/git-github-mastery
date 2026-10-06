#!/usr/bin/env bash
# Chapter 14C, section 14C.3: a resolution recorded during a merge is reused by a rebase, and
# rerere.autoUpdate stages the result.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c rerere-rebase
fx_rerere_recorded 'model: bge-small\ntop_k: 50\nrerank: true\n'
cd ranker || exit 1

snip 01-rebase
run 'git switch -q feature/rerank'
run_rc 'git rebase main'

snip 02-continue
run 'git status -s'
run 'cat retrieval.yaml'
run 'git add retrieval.yaml'
run 'git rebase --continue'
run 'git log --oneline --graph --all'

quiet 'git reset --hard ORIG_HEAD'

snip 03-autoupdate
run 'git config set rerere.autoUpdate true'
run_rc 'git -c advice.mergeConflict=false rebase main'
run 'git status -s'
run 'git rebase --continue'

lab_end
