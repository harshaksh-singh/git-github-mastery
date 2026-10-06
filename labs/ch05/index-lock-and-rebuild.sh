#!/usr/bin/env bash
# Two operational facts about the index file: every writer takes .git/index.lock, and an
# index that is lost or corrupt can be rebuilt from HEAD, minus whatever was only staged.
# Chapter 5, section 5.15.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 index-lock-and-rebuild

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-lock
note 'Imitate a Git process that died while it was writing the index.'
run 'touch .git/index.lock'
run "echo 'TOP_K = 8' > src/retriever.py"
run_rc 'git add src/retriever.py'
note 'Reading still works. Only writers need the lock.'
run 'git status --short'
note 'After checking that no Git process is running, remove the stale lock.'
run 'rm .git/index.lock'
run 'git add src/retriever.py'
run 'git status --short'

snip 02-corrupt
note 'One staged change (retriever.py) and one unstaged change (settings.yaml) exist.'
run "echo 'temperature: 0.2' >> config/settings.yaml"
run 'git status --short'
note 'Now the index file is damaged.'
run "printf 'garbage' > .git/index"
run_rc 'git status'

snip 03-rebuild
note 'Delete the damaged file. With no index, every path in HEAD looks deleted and every file looks new.'
run 'rm .git/index'
run 'git status --short'
note 'Rebuild the index from HEAD. A mixed reset writes the index and leaves the working tree alone.'
run 'git reset'
run 'git status --short'

snip 04-what-was-lost
note 'The files are intact. What is gone is the knowledge of which change was staged.'
run 'git diff --stat'
run 'git fsck'

lab_end
