#!/usr/bin/env bash
# Chapter 11, section 11.10: "git clean" removes untracked files, which have no object in the
# repository and therefore no way back. Dry runs first (-n), the meaning of -d, -x, -X and -e,
# the refusal without -f, and the proof that a cleaned file is gone.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 clean

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'timeout_s: 30\n' > serve.yaml && printf '__pycache__/\n*.log\n.env\n' > .gitignore && git add . && git commit -m 'Add BM25 ranker and serving config'"
# Untracked files, an untracked directory, ignored files, a nested repository, one tracked edit.
quiet "mkdir -p __pycache__ scratch/notes vendor/tokenizers"
quiet "printf 'bytecode\n' > __pycache__/rank.cpython-312.pyc && printf 'epoch 1 loss 0.42\n' > train.log && printf 'API_KEY=local-dev-only\n' > .env"
quiet "printf '{\"query\": \"q1\", \"scores\": [0.9, 0.4]}\n' > debug_dump.json && printf 'try a larger rerank window\n' > scratch/notes/ideas.md"
quiet "git init vendor/tokenizers && printf 'vendored copy\n' > vendor/tokenizers/README.md"
quiet "printf 'timeout_s: 10\n' > serve.yaml"

snip 01-status
run 'git status -s --ignored'

snip 02-refuses-without-force
run_rc 'git clean'

snip 03-dry-runs
run 'git clean -n'
run 'git clean -n -d'
run 'git clean -n -d -X'
run 'git clean -n -d -x'
run 'git clean -n -d -e scratch/'

snip 04-clean
run 'git clean -f -d'
run 'git status -s --ignored'

snip 05-gone-for-good
run "printf '{\"query\": \"q1\", \"scores\": [0.9, 0.4]}\n' | git hash-object --stdin"
run_rc 'git cat-file -t d702a51f40a7856802f55fc97f9a9c06a50bcad4'
run 'git fsck'

lab_end
