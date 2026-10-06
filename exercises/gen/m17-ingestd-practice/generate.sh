#!/usr/bin/env bash
# Practice repositories for the Module 17 exercises 17.1 to 17.8 (the index, refs and the files
# of the .git directory). Each exercise has its own directory ex-17-N/ with a piece of the
# project "ingestd" (a daemon that ingests documents into a search index).
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m17-ingestd-practice

seed() {
  put src/ingest.py <<'F'
"""Reads documents and hands them to the indexer."""

BATCH = 100


def batches(docs):
    for start in range(0, len(docs), BATCH):
        yield docs[start:start + BATCH]
F
  put docs/format.md <<'F'
# Input format

One JSON document per line: `id`, `title`, `body`.
F
  put README.md <<'F'
# ingestd

Ingests documents into the search index.
F
  _c 'Add batching ingester'
  printf 'max_batch: 100\nworkers: 4\n' > config.yaml
  _c 'Add configuration'
}

# ---------------------------------------------------------------- 17.1 the index as a table
quiet 'git init ex-17-1'; cd ex-17-1 || exit 1
seed
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.2 loose refs and packed refs
quiet 'git init ex-17-2'; cd ex-17-2 || exit 1
quiet 'git config set maintenance.auto false'
seed
quiet 'git branch feature/retries'
quiet "git tag -a v0.1.0 -m 'ingestd 0.1.0'"
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.3 refs by plumbing
quiet 'git init ex-17-3'; cd ex-17-3 || exit 1
seed
printf 'max_batch: 200\nworkers: 4\n' > config.yaml
_c 'Double the batch size'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.4 the index during a conflict
quiet 'git init ex-17-4'; cd ex-17-4 || exit 1
seed
quiet 'git switch -c feature/streaming'
printf 'max_batch: 500\nworkers: 4\n' > config.yaml
quiet 'git rm -q docs/format.md'
printf 'def stream(source):\n    yield from source\n' > src/stream.py
_c 'Stream documents instead of batching'
quiet 'git switch main'
printf 'max_batch: 50\nworkers: 4\n' > config.yaml
printf '\nFields may be empty but must be present.\n' >> docs/format.md
printf 'def stream(lines):\n    return iter(lines)\n' > src/stream.py
_c 'Smaller batches, stricter format, line streaming'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.5 what rev-parse answers
quiet 'git init ex-17-5'; cd ex-17-5 || exit 1
seed
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.6 a commit without the index
quiet 'git init ex-17-6'; cd ex-17-6 || exit 1
seed
printf '\n## Limits\n\nAt most 1 MB per document.\n' >> docs/format.md
_c 'Document the size limit'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.7 a branch that Git ignores
quiet 'git init ex-17-7'; cd ex-17-7 || exit 1
quiet 'git config set maintenance.auto false'
seed
quiet 'git switch -c release/1.0'
printf 'max_batch: 100\nworkers: 8\n' > config.yaml
_c 'Use eight workers in the 1.0 line'
quiet 'git pack-refs --all'
printf 'max_batch: 100\nworkers: 8\ntimeout_seconds: 30\n' > config.yaml
_c 'Add an ingest timeout to the 1.0 line'
quiet 'git switch main'
printf '7c3f9a1b2d4e\n' > .git/refs/heads/release/1.0          # a half-written file
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 17.8 an edit that Git does not see
mkdir ex-17-8 && cd ex-17-8 || exit 1
ex_server; ex_clone work; cd work || exit 1
seed
quiet 'git push -u origin main'
quiet 'git update-index --skip-worktree config.yaml'
printf 'max_batch: 100\nworkers: 16\n' > config.yaml        # a different size, so the cached stat data cannot match
cd .. || exit 1
ex_clone asha; cd asha || exit 1
as asha
printf 'queue: ingest-main\nmax_batch: 100\nworkers: 4\n' > config.yaml
_c 'Name the ingest queue'
quiet 'git push'
as you
cd .. || exit 1
rm -rf asha
cd "$LAB_DIR" || exit 1

unset -f seed
ex_end
