#!/usr/bin/env bash
# Chapter 24, section 24.9: computing which projects a branch touches (what a monorepo CI needs
# before it can decide which jobs to run), and why a shallow CI clone cannot compute it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch24 affected-projects
. "$LAB_SCRIPT_DIR/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1

snip 01-three-dot
run 'cd orbit'
run "git log --oneline --graph -4 main feature/rerank-cache"
note 'What the branch changed since it forked (three dots: diff from the merge base):'
run 'git diff --name-only main...feature/rerank-cache'
run 'git diff --name-only main...feature/rerank-cache | cut -d/ -f1-2 | sort -u'
note 'Two dots compare the two tips, and blame the branch for what main did meanwhile:'
run 'git diff --name-only main..feature/rerank-cache | cut -d/ -f1-2 | sort -u'
run 'cd ..'

snip 02-shallow-ci
note 'The CI job clones the branch with depth 1 and fetches the tip of main the same way:'
run 'git clone -q --depth 1 --branch feature/rerank-cache "file://$PWD/server/orbit.git" ci-shallow'
run 'cd ci-shallow'
run 'git fetch -q --depth 1 origin main:refs/remotes/origin/main'
run 'git log --oneline --all'
run_rc 'git diff --name-only origin/main...HEAD'
run_rc 'git merge-base origin/main HEAD'
run 'cd ..'

snip 03-blobless-ci
note 'A blobless clone without a checkout has every commit and tree and not a single file:'
run 'git clone -q --filter=blob:none --no-checkout --branch feature/rerank-cache "file://$PWD/server/orbit.git" ci-blobless'
run 'cd ci-blobless'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run 'git merge-base origin/main HEAD'
run 'git diff --name-only origin/main...HEAD | cut -d/ -f1-2 | sort -u'
note 'Then check out only what the job needs:'
run 'git sparse-checkout set services/ranker libs/tokenizer'
run 'git checkout -q'
run "find . -path ./.git -prune -o -type f -print | sort"

lab_end
