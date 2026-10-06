#!/usr/bin/env bash
# Chapter 14C, section 14C.3: rerere across a repeated merge. Enable it, watch the conflict being
# recorded in .git/rr-cache, resolve once in a test merge that is thrown away, and see the real
# merge reuse the resolution.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c rerere-merge
fx_rerere_repo
cd ranker || exit 1

snip 01-first-conflict
run 'git log --oneline --graph --all'
run 'git config set rerere.enabled true'
run 'git switch -q feature/rerank'
run_rc 'git merge main'

snip 02-recorded
run 'ls .git/rr-cache'
run 'cat .git/rr-cache/*/preimage'
run 'cat retrieval.yaml'
run 'git rerere status'

snip 03-resolve
run "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml"
run 'git rerere diff'
run 'git commit -am "Test merge of main"'
run 'ls .git/rr-cache/*'
run 'cat .git/rr-cache/*/postimage'

snip 04-throw-away
note 'The test merge served its purpose. Remove it; the recorded resolution stays.'
run 'git reset --hard HEAD^'
run 'ls .git/rr-cache/*'

snip 05-real-merge
run 'git switch -q main'
run_rc 'git merge feature/rerank'

snip 06-state
run 'git status -s'
run 'cat retrieval.yaml'
run 'git rerere remaining'
run 'git ls-files -u'

snip 07-finish
run 'git add retrieval.yaml'
run 'git commit --no-edit'
run 'git log --oneline --graph'

lab_end
