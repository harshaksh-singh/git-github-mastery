#!/usr/bin/env bash
# Final test, section 4 (Merge): prediction items P1 and P2, diagram items G1 and G2 and
# interpretation items I1 and I2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s04

# ---- P1: the strategy option "ours" is not the strategy "ours"
snip p1-setup
run 'git init -q samplerconf'
run 'cd samplerconf'
run "printf 'temperature: 0.7\ntop_p: 0.9\n' > sampling.yaml"
run "printf 'max_tokens: 256\n' > limits.yaml"
run 'git add .'
run 'git commit -q -m "Add sampling defaults"'
run 'git switch -q -c feature/deterministic'
run "printf 'temperature: 0.0\ntop_p: 0.9\n' > sampling.yaml"
run "printf 'max_tokens: 1024\n' > limits.yaml"
run 'git commit -q -a -m "Deterministic sampling, longer answers"'
run 'git switch -q main'
run "printf 'temperature: 0.2\ntop_p: 0.9\n' > sampling.yaml"
run 'git commit -q -a -m "Lower the temperature"'
run 'git merge -q -X ours -m "Merge feature/deterministic" feature/deterministic'
snip p1-answer
run 'cat sampling.yaml'
run 'cat limits.yaml'
run 'git log --oneline --graph'
cd "$LAB_DIR"

# ---- P2: --ff-only on diverged branches, and a merge that touches nothing
snip p2-setup
run 'git init -q indexer'
run 'cd indexer'
run "printf 'shards: 4\n' > index.yaml"
run 'git add . && git commit -q -m "Add index settings"'
run 'git switch -q -c feature/replicas'
run "printf 'replicas: 2\n' > replicas.yaml"
run 'git add . && git commit -q -m "Add replica settings"'
run 'git switch -q main'
run "printf 'shards: 8\n' > index.yaml"
run 'git commit -q -a -m "Double the shards"'
snip p2-answer
run_rc 'git merge --ff-only feature/replicas'
run 'git status -sb'
run_rc 'git merge-tree --write-tree --name-only main feature/replicas'
run 'git log --oneline --graph --all'
cd "$LAB_DIR"

# ---- G1: one merge, three branches
snip g1-setup
run 'git init -q metricsd'
run 'cd metricsd'
run 'git commit -q --allow-empty -m "A: add the collector"'
run 'git switch -q -c feature/histograms'
run 'git commit -q --allow-empty -m "B: add histograms"'
run 'git switch -q -c feature/exemplars main'
run 'git commit -q --allow-empty -m "C: add exemplars"'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "D: add the scrape endpoint"'
run 'git merge -q -m "M: merge histograms and exemplars" feature/histograms feature/exemplars'
snip g1-answer
run 'git log --graph --oneline --all --decorate'
run 'git cat-file -p HEAD | grep -c "^parent"'
run 'git log -1 --format=%s HEAD^3'
run 'git log --first-parent --format=%s'
cd "$LAB_DIR"

# ---- G2: two branches that merged each other
quiet 'git init -q pricing'
cd pricing || exit 1
printf 'currency: EUR\n' > price.yaml
quiet 'git add . && git commit -q -m "A: add price settings"'
quiet 'git switch -q -c develop'
printf 'tax: 19\n' > tax.yaml
quiet 'git add . && git commit -q -m "C: add tax settings"'
quiet 'git switch -q main'
printf 'rounding: half-even\n' > rounding.yaml
quiet 'git add . && git commit -q -m "B: add rounding settings"'
b=$(git rev-parse HEAD)
quiet 'git merge -q --no-ff -m "M1: merge develop into main" develop~0'
quiet 'git switch -q develop'
quiet "git merge -q --no-ff -m 'M2: merge main into develop' $b"
snip g2-graph
run 'git log --graph --oneline --all --decorate'
snip g2-answer
run 'git merge-base --all main develop | xargs -n1 git log -1 --format=%s'
run 'git merge-base main develop | xargs git log -1 --format=%s'
cd "$LAB_DIR"

# ---- I1: an edit that follows a rename
quiet 'git init -q toolkit'
cd toolkit || exit 1
mkdir utils
printf 'def chunk(text, size):\n    words = text.split()\n    out = []\n    for i in range(0, len(words), size):\n        out.append(" ".join(words[i:i + size]))\n    return out\n' > utils/text.py
quiet 'git add . && git commit -q -m "Add chunk helper"'
quiet 'git switch -q -c refactor/layout'
mkdir chunking
quiet 'git mv utils/text.py chunking/split.py'
quiet 'git commit -q -m "Move the chunk helper into its own package"'
quiet 'git switch -q -c fix/empty-input main'
printf 'def chunk(text, size):\n    words = text.split()\n    if not words:\n        return []\n    out = []\n    for i in range(0, len(words), size):\n        out.append(" ".join(words[i:i + size]))\n    return out\n' > utils/text.py
quiet 'git commit -q -a -m "Return an empty list for empty input"'
quiet 'git switch -q refactor/layout'
snip i1-transcript
run 'git ls-files'
run 'git log --oneline --name-status -1 fix/empty-input'
run 'git merge -m "Merge fix/empty-input" fix/empty-input'
run 'git ls-files'
run 'grep -n "if not words" -A1 chunking/split.py'
cd "$LAB_DIR"

# ---- I2: one side edits, the other side deletes
quiet 'git init -q legacy-api'
cd legacy-api || exit 1
printf 'def v1_search(q):\n    return backend.search(q)\n' > v1.py
printf 'def v2_search(q, k=10):\n    return backend.search(q, k)\n' > v2.py
quiet 'git add . && git commit -q -m "Add both API versions"'
quiet 'git switch -q -c cleanup/remove-v1'
quiet 'git rm -q v1.py && git commit -q -m "Remove the v1 endpoint"'
quiet 'git switch -q main'
printf 'def v1_search(q):\n    return backend.search(q, timeout=5)\n' > v1.py
quiet 'git commit -q -a -m "Add a timeout to v1 search"'
snip i2-transcript
run_rc 'git merge cleanup/remove-v1'
run 'git status --short'
run 'git ls-files -u'
run 'ls'
lab_end
