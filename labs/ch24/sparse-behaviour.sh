#!/usr/bin/env bash
# Chapter 24, section 24.5: how other commands behave inside a sparse checkout, and the two
# ways a working tree ends up with files outside its cone.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 sparse-behaviour
. "$LAB_SCRIPT_DIR/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git clone "file://$PWD/server/orbit.git" dev'
cd dev || exit 1
quiet 'git config set maintenance.auto false'
quiet 'git sparse-checkout set services/ranker libs/tokenizer'

snip 01-reads
note 'History and objects are complete. Only the working tree is narrow:'
run 'git log --oneline -2 -- services/gateway'
run 'git show HEAD:services/gateway/config.yaml'
note 'A search of the working tree sees only what is checked out; --cached searches the index:'
run_rc 'git grep -l tenant'
run 'git grep -l --cached tenant'

snip 02-status-work
note 'The work of one status, counted (Chapter 26, section 26.2 explains the pipeline):'
run "GIT_TRACE2_PERF=1 git status 2>&1 >/dev/null | awk -F'|' '\$4 ~ /data/ {gsub(/[ .]/, \"\", \$NF); gsub(/ /, \"\", \$(NF-1)); print \$(NF-1), \$NF}' | grep -e read/cache_nr -e sum_lstat -e visited"

snip 03-add-outside
note 'A new file in a directory outside the cone:'
run 'mkdir -p services/gateway'
run "printf '# Gateway notes\\n\\nRoutes are versioned under /v1.\\n' > services/gateway/NOTES.md"
run_rc 'git add services/gateway/NOTES.md'
run 'git status --short'

snip 04-add-sparse
run 'git add --sparse services/gateway/NOTES.md'
run "git commit -q -m 'gateway: add notes on route versioning'"
run 'git ls-files -t services/gateway'
note 'The file is committed and still on disk although its directory is outside the cone:'
run 'ls services/gateway'
run 'git sparse-checkout reapply'
run 'ls services'
run 'git ls-files -t services/gateway/NOTES.md'

snip 05-untracked-blocks
note 'Widen the cone, leave an untracked file behind, and narrow it again:'
run 'git sparse-checkout add pipelines/eval'
run "printf 'recall@10 = 0.83\\n' > pipelines/eval/results.tmp"
run 'git sparse-checkout set services/ranker libs/tokenizer'
run 'find pipelines -type f'
run 'git status --short'

snip 06-clean
note 'Preview first: the cleanup removes the whole directory, the untracked file included.'
run 'git sparse-checkout clean --dry-run'
run_rc 'git sparse-checkout clean'
run 'git sparse-checkout clean -f'
run_rc 'ls pipelines'

snip 07-ignored-lost
note 'The same sequence with a file that .gitignore covers (build/ is ignored in this repository):'
run 'git sparse-checkout add pipelines/eval'
run "mkdir pipelines/eval/build && printf 'cached features\\n' > pipelines/eval/build/features.bin"
run 'git status --short --ignored'
run 'git sparse-checkout set services/ranker libs/tokenizer'
run_rc 'ls pipelines'

lab_end
