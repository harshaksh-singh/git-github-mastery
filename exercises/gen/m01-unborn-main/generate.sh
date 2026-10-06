#!/usr/bin/env bash
# Exercise 1.9 (Level 4): "git log says there are no commits".
# Builds the repository chunk-index/. Read SYMPTOMS.md, not this file, before you start: the
# script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m01-unborn-main
ex_begin m01-unborn-main

quiet 'git init chunk-index'
cd chunk-index || exit 1
mkdir -p chunkindex
printf 'def build(chunks):\n    return {i: c for i, c in enumerate(chunks)}\n' > chunkindex/build.py
_c 'Add in-memory chunk index'
printf 'def lookup(index, i):\n    return index.get(i)\n' > chunkindex/lookup.py
_c 'Add lookup by position'
printf '# chunk-index\n\nMaps chunk positions to chunk text.\n' > README.md
_c 'Add README'
ex_note tip "$(git rev-parse HEAD)"

# The interrupted "rename the default branch" script: it moved the ref file by hand and never
# told HEAD, which still names refs/heads/main.
mv .git/refs/heads/main .git/refs/heads/trunk

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
