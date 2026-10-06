#!/usr/bin/env bash
# Staging a deletion, a rename and a binary file: what each one is in terms of index entries.
# Chapter 5, section 5.7.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 stage-deletions-renames-binary

git init -q support-bot
cd support-bot || exit 1
mkdir -p src docs
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n\ndef retrieve(question):\n    return []\n' > src/retriever.py
printf 'Old design notes.\n' > docs/old-notes.md
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-deletion
run 'git ls-files --stage'
run 'rm docs/old-notes.md'
run 'git status --short'
note 'Staging a deletion removes the index entry. "git add" does it for a path that is gone.'
run 'git add docs/old-notes.md'
run 'git status --short'
run 'git ls-files --stage'

snip 02-rename
run 'mv src/retriever.py src/search.py'
run 'git status --short'
run 'git add src/retriever.py src/search.py'
run 'git status --short'
run 'git ls-files --stage'
note 'One entry removed, one entry added with the same blob ID. "Renamed" is a conclusion status draws.'

snip 03-binary
mkdir -p assets
printf '\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\020' > assets/logo.png
run 'git add assets/logo.png'
run 'git ls-files --stage assets'
run 'git diff --cached --stat -- assets'
run 'git diff --cached -- assets'
run 'git diff --cached --numstat -- assets'

snip 04-binary-change
quiet 'git commit -m "Reorganise search module and add logo"'
note 'Change one byte of the image.'
printf '\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\040' > assets/logo.png
run 'git diff --stat'
note 'There are no hunks to choose from in a binary file.'
run 'git add -p assets/logo.png'
run 'git add assets/logo.png'
run 'git ls-files --stage assets'

lab_end
