#!/usr/bin/env bash
# "git ls-files": the command that reads the index and compares it with the working tree.
# Chapter 5, section 5.11.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 ls-files-tour

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config scripts
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
printf '#!/bin/sh\necho eval\n' > scripts/run_eval.sh
chmod +x scripts/run_eval.sh
printf 'LLM_API_KEY=lab-secret-0001\n' > .env
quiet 'git add . && git commit -m "Add service skeleton"'
printf '.env\n*.log\n__pycache__/\n' > .gitignore
quiet 'git add .gitignore && git commit -m "Add ignore rules"'

printf 'TOP_K = 8\n' > src/retriever.py               # modified
rm config/settings.yaml                               # deleted
printf 'Try a reranker.\n' > notes.md                 # untracked
printf 'started\n' > server.log                       # ignored
mkdir -p src/__pycache__
printf 'bytecode\n' > src/__pycache__/app.cpython-314.pyc

snip 01-cached-and-stage
note 'Default (-c, --cached): the paths in the index.'
run 'git ls-files'
note '-s, --stage: mode, blob ID and stage number for each entry.'
run 'git ls-files --stage'

snip 02-against-working-tree
note '-m: tracked paths whose working tree file differs from the index. A deleted file counts.'
run 'git ls-files --modified'
note '-d: tracked paths whose working tree file is gone.'
run 'git ls-files --deleted'

snip 03-others
note '-o: paths with no index entry. Ignore rules apply only when you ask for them.'
run 'git ls-files --others'
run 'git ls-files --others --exclude-standard'
note '-o -i: untracked paths that an ignore rule matches.'
run 'git ls-files --others --ignored --exclude-standard'
note '-c -i: TRACKED paths that an ignore rule matches. This finds the already-tracked trap.'
run 'git ls-files --cached --ignored --exclude-standard'

snip 04-ignored-needs-c-or-o
run_rc 'git ls-files --ignored --exclude-standard'

snip 05-tags
note '-t prefixes each path with a status tag: H cached, C changed, R removed, ? other.'
run 'git ls-files -t --cached --modified --deleted --others --exclude-standard'

snip 06-scripting
note 'Is this path tracked? The exit status answers.'
run_rc 'git ls-files --error-unmatch src/app.py'
run_rc 'git ls-files --error-unmatch notes.md'
note 'A custom format, one field at a time.'
run "git ls-files --abbrev --format='%(objectmode) %(objectname) %(objectsize:padded) %(path)'"

lab_end
