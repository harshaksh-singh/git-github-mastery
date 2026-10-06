#!/usr/bin/env bash
# "git add -u", "git add -A" and "git add ." compared from inside a subdirectory, with
# --dry-run so that nothing is staged. Chapter 5, section 5.8.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 add-scope

git init -q support-bot
cd support-bot || exit 1
mkdir -p src docs
printf '# Support bot\n' > README.md
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n' > src/retriever.py
printf 'User guide.\n' > docs/guide.md
quiet 'git add . && git commit -m "Add service skeleton"'

# Outside src/: one modification, one deletion, one new file.
printf '\nSee docs/ for details.\n' >> README.md
rm docs/guide.md
printf 'Try a reranker.\n' > notes.md
# Inside src/: one modification, one deletion, one new file.
printf '\ndef health():\n    return "ok"\n' >> src/app.py
rm src/retriever.py
printf 'SYSTEM = "You are a support assistant."\n' > src/prompts.py

snip 01-state
run 'git status --short'
run 'cd src'
note 'From a subdirectory, the short format shows paths relative to where you stand.'
run 'git status --short'

snip 02-dot
note 'A pathspec limits the command. "." means this directory and below.'
run 'git add --dry-run .'

snip 03-update
note '-u: every tracked path in the whole working tree. No new files.'
run 'git add --dry-run -u'
note '-u with a pathspec: tracked paths in this directory and below.'
run 'git add --dry-run -u .'

snip 04-all
note '-A: every change in the whole working tree, new files included.'
run 'git add --dry-run -A'

snip 05-no-all
note '--no-all with a pathspec: new and modified files, but removals are left unstaged.'
run 'git add --dry-run --no-all .'

lab_end
