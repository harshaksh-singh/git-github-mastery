#!/usr/bin/env bash
# Git tracks files, not directories: empty directories cannot be staged, and a directory
# disappears with its last tracked file. Chapter 4, section 4.11.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 empty-directories

git init -q support-bot
cd support-bot || exit 1
mkdir -p src docs
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'Old design notes.\n' > docs/old-notes.md
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-invisible
run 'mkdir -p data/raw data/processed'
run 'git status'
run 'git add data'
run 'git status --short'
run 'git ls-files data'

snip 02-placeholder
note 'The index holds file paths only. A directory reaches a commit through a file inside it.'
run "printf '*\n!.gitignore\n' > data/raw/.gitignore"
run 'git add data/raw/.gitignore'
run 'git status --short'
run 'git commit -m "Keep data/raw in the repository, ignore its content"'
run 'git ls-tree -r --name-only HEAD'
run "echo '{\"id\": 1}' > data/raw/tickets.jsonl"
run 'git status --short'

snip 03-last-file-leaves
note 'Remove the only tracked file in docs/: Git removes the directory with it.'
run 'git rm docs/old-notes.md'
run_rc 'ls docs'
note 'An untracked file keeps a directory alive on disk, and Git still does not track the directory.'
run 'git restore --staged --worktree docs/old-notes.md'
run "echo 'draft' > docs/draft.md"
run 'git rm docs/old-notes.md'
run 'ls docs'

lab_end
