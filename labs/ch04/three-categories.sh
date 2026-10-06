#!/usr/bin/env bash
# Tracked, untracked and ignored: the three categories a path in the working tree can be in,
# and the commands that list each one. Chapter 4, section 4.3.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 three-categories

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf 'import retriever\n\ndef answer(question):\n    return retriever.retrieve(question)\n' > src/app.py
printf 'TOP_K = 5\n\ndef retrieve(question):\n    return []\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
printf '.env\n__pycache__/\ndata/\n' > .gitignore
quiet 'git add . && git commit -m "Add service skeleton"'

# One path of each kind that is not tracked.
mkdir -p notes data src/__pycache__
printf 'Try a reranker after retrieval.\n' > notes/ideas.md
printf 'LLM_API_KEY=lab-secret-0001\n' > .env
printf '{"id": 1, "text": "refund not received"}\n' > data/tickets.jsonl
printf 'compiled bytecode\n' > src/__pycache__/app.cpython-314.pyc

snip 01-status
run 'cat .gitignore'
run 'git status'

snip 02-status-ignored
run 'git status --ignored'

snip 03-ls-files
note 'Tracked: every path that has an entry in the index.'
run 'git ls-files'
note 'Untracked and not ignored.'
run 'git ls-files --others --exclude-standard'
note 'Untracked and ignored.'
run 'git ls-files --others --ignored --exclude-standard'

snip 04-transitions
note 'Untracked becomes tracked the moment the path gets an index entry.'
run 'git add notes/ideas.md'
run 'git ls-files notes'
note 'An ignored path is refused unless you force it.'
run_rc 'git add .env'
run 'git status --short --ignored'

lab_end
