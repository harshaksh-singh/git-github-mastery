#!/usr/bin/env bash
# Model answers for exercises 18.1 to 18.8 (Module 18: clone variants, sparse checkout, transfer)
# as real transcripts on the practice repositories built by
# exercises/gen/m18-searchstack-practice/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m18
ex_load m18-searchstack-practice
TYPES="git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
MISSING="git rev-list --objects --missing=print --all | grep -c '^?'"

cd ex-18-1 || exit 1
snip 18-0-server
run 'git -C server.git log --graph --oneline --decorate --all'
snip 18-1-shallow
run 'git clone --depth 1 "file://$PWD/server.git" shallow'
run 'cd shallow'
run 'git log --oneline'
run 'git rev-parse --is-shallow-repository'
run 'cat .git/shallow'
run 'git cat-file -p HEAD | grep parent'
run_rc 'git cat-file -t HEAD^1'
snip 18-1-refs
run 'git branch -r'
run 'git tag'
run 'git config get --all remote.origin.fetch'
snip 18-1-unshallow
run 'git fetch -q --unshallow'
run 'git rev-parse --is-shallow-repository'
run 'git rev-list --count HEAD'
run 'git tag'
run 'git branch -r'
cd "$LAB_DIR" || exit 1

cd ex-18-2 || exit 1
snip 18-2-blobless
run 'git clone -q --filter=blob:none "file://$PWD/server.git" blobless && cd blobless'
run "$TYPES"
run "$MISSING"
run 'git config get remote.origin.promisor'
run 'git config get remote.origin.partialclonefilter'
snip 18-2-on-demand
run 'git log --oneline -3 -- docs'
run "$MISSING"
run 'git show v0.1.0:docs/architecture.md'
run "$MISSING"
cd "$LAB_DIR" || exit 1

cd ex-18-3 || exit 1
snip 18-3-sparse
run 'git clone -q "file://$PWD/server.git" work && cd work'
run 'git ls-files'
run 'git sparse-checkout set --cone services/reranker libs/tokenize'
run 'git sparse-checkout list'
run 'find . -path ./.git -prune -o -type f -print | sort'
snip 18-3-index
run 'git ls-files -t'
run 'git status'
snip 18-3-disable
run 'git sparse-checkout disable'
run 'find . -path ./.git -prune -o -type f -print | wc -l'
cd "$LAB_DIR" || exit 1

cd ex-18-4 || exit 1
snip 18-4-graph
run 'git clone -q --depth 2 "file://$PWD/server.git" two'
run 'git -C two log --graph --oneline'
snip 18-4-count
run 'git -C two rev-list --count HEAD'
run 'git -C server.git rev-list --count main'
run 'wc -l < two/.git/shallow'
cd "$LAB_DIR" || exit 1

cd ex-18-5 || exit 1
snip 18-5-single
run 'git clone -q --single-branch "file://$PWD/server.git" single && cd single'
run 'git branch -r'
run 'git config get --all remote.origin.fetch'
run 'git tag'
run_rc 'git switch release/0.2'
snip 18-5-widen
run 'git fetch'
run 'git remote set-branches --add origin release/0.2'
run 'git config get --all remote.origin.fetch'
run 'git fetch'
run 'git switch release/0.2'
cd "$LAB_DIR" || exit 1

cd ex-18-6 || exit 1
snip 18-6-history-only
run 'git clone -q --filter=blob:none --no-checkout "file://$PWD/server.git" history && cd history'
run "$TYPES"
run 'git log --oneline -- services/reranker'
run "$TYPES"
snip 18-6-one-blob
run 'git show HEAD:services/reranker/rerank.py'
run "$TYPES"
snip 18-6-treeless
run 'cd .. && git clone -q --filter=tree:0 --no-checkout "file://$PWD/server.git" treeless && cd treeless'
run "$TYPES"
run 'git log --oneline -- services/reranker'
run "$TYPES"
cd "$LAB_DIR" || exit 1

cd ex-18-7/ci || exit 1
snip 18-7-symptom
run_rc 'scripts/changed-services.sh'
run 'git merge-base origin/main HEAD; echo "exit status: $?"'
run_rc 'git diff --name-only origin/main...HEAD'
snip 18-7-diagnose
run 'git rev-parse --is-shallow-repository'
run 'git log --graph --oneline --all'
run 'cat .git/shallow'
snip 18-7-fix
run 'git fetch -q --unshallow'
run 'git log --graph --oneline --all | head -6'
run 'git merge-base origin/main HEAD'
run 'scripts/changed-services.sh; echo "exit status: $?"'
run 'git diff --name-only origin/main...HEAD'
cd "$LAB_DIR" || exit 1

cd ex-18-8/work || exit 1
snip 18-8-symptom
run 'ls'
run 'git ls-files docs'
run 'git status -sb'
run "mkdir docs && echo '# Notes' > docs/notes.md"
run_rc 'git add docs/notes.md'
snip 18-8-diagnose
run 'git sparse-checkout list'
run 'git ls-files -t docs services'
snip 18-8-fix
run 'git sparse-checkout add docs'
run 'ls docs'
run 'git add docs/notes.md'
run 'git status -sb'
lab_end
