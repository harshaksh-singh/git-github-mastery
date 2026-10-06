#!/usr/bin/env bash
# What the working tree is, where it starts and ends, and why Git can rebuild tracked
# files but not the things it was never told about. Chapter 4, section 4.2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 worktree-basics

snip 01-where
run 'git init support-bot'
run 'cd support-bot'
mkdir -p src config
printf 'import retriever\n\ndef answer(question):\n    return retriever.retrieve(question)\n' > src/app.py
printf 'TOP_K = 5\n\ndef retrieve(question):\n    return []\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'
run 'git rev-parse --show-toplevel'
run 'git rev-parse --git-dir'
run 'cd src'
run 'git rev-parse --show-toplevel --show-prefix --git-dir'
run 'git rev-parse --is-inside-work-tree'
run 'cd ..'

snip 02-bare
note 'A bare repository is a repository without a working tree.'
run 'git init --bare ../central.git'
run 'git -C ../central.git rev-parse --is-bare-repository'
run_rc 'git -C ../central.git status'

snip 03-rebuild
note 'Tracked content can be rebuilt from the index. Untracked content cannot.'
run "echo 'LLM_API_KEY=lab-secret-0001' > .env"
run 'rm -r src config .env'
run 'git status --short'
run 'git restore .'
run 'find . -path ./.git -prune -o -type f -print | sort'
run_rc 'git restore .env'

lab_end
