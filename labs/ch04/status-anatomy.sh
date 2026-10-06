#!/usr/bin/env bash
# The anatomy of "git status": long, short and porcelain forms, and status as two
# comparisons (HEAD against the index, the index against the working tree). Chapter 4, section 4.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 status-anatomy

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config docs
printf 'import retriever\n\ndef answer(question):\n    return retriever.retrieve(question)\n' > src/app.py
printf 'TOP_K = 5\n\ndef retrieve(question):\n    return []\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
printf 'fastapi\nnumpy\n' > requirements.txt
printf '# Support bot\n\nRoutes support tickets to an LLM with retrieval.\n' > README.md
printf 'Old design notes.\n' > docs/old-notes.md
quiet 'git add . && git commit -m "Add service skeleton"'

# Produce one path for each interesting state.
printf 'temperature: 0.2\n' >> config/settings.yaml          # staged modification
git add config/settings.yaml
printf 'TOP_K = 8\n\ndef retrieve(question):\n    return []\n' > src/retriever.py
git add src/retriever.py                                     # staged ...
printf '\ndef rerank(hits):\n    return hits\n' >> src/retriever.py   # ... and modified again
printf '\ndef health():\n    return "ok"\n' >> src/app.py     # modified, not staged
git mv README.md docs/README.md                              # staged rename
git rm -q docs/old-notes.md                                  # staged deletion
rm requirements.txt                                          # deletion, not staged
printf 'SYSTEM = "You are a support assistant."\n' > src/prompts.py
git add src/prompts.py                                       # new file, staged
mkdir -p scratch
printf 'print("try")\n' > scratch/try.py                     # untracked
printf 'x = 1\n' > scratch/notes.py

snip 01-long
run 'git status'

snip 02-short
run 'git status --short'
run 'git status --short --branch'

snip 03-two-comparisons
note 'Comparison 1: HEAD against the index. This is the X column.'
run 'git diff --cached --name-status'
note 'Comparison 2: the index against the working tree. This is the Y column.'
run 'git diff --name-status'
note 'Third pass: paths in the working tree that have no index entry.'
run 'git ls-files --others --exclude-standard'

snip 04-porcelain
run 'git status --porcelain'
run 'git status --porcelain=v2 --branch'

snip 05-untracked-modes
run 'git status --short --untracked-files=all'
run 'git status --short --untracked-files=no'

lab_end
