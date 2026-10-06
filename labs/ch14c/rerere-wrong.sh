#!/usr/bin/env bash
# Chapter 14C, section 14C.3: the risk of rerere. A wrong resolution is replayed without a
# question; "git rerere forget" and "git restore --merge" bring the conflict back so that it can
# be resolved, and recorded, again.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c rerere-wrong
# The recorded resolution keeps top_k at 20 and turns reranking on: the reranker would see 20
# candidates instead of the 50 it was tuned for.
fx_rerere_recorded 'model: bge-small\ntop_k: 20\nrerank: true\n'
cd ranker || exit 1

snip 01-replayed
run 'cat .git/rr-cache/*/postimage'
run_rc 'git merge feature/rerank'
run 'cat retrieval.yaml'

snip 02-forget
run 'git rerere forget retrieval.yaml'
run 'ls .git/rr-cache/*'
run 'git restore --merge retrieval.yaml'
run 'cat retrieval.yaml'

snip 03-record-again
run "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml"
run 'git add retrieval.yaml'
run 'git commit --no-edit'
run 'cat .git/rr-cache/*/postimage'

lab_end
