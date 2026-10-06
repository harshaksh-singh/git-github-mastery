#!/usr/bin/env bash
# The cached stat data in each index entry: how Git decides that a file is unchanged
# without reading it, and what "refreshing the index" means. Chapter 5, section 5.14.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 stat-cache

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n' > src/retriever.py
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-entry
note 'The stat fields are your machine and your clock, so this transcript masks their values with N.'
run "git ls-files --debug src/app.py | sed -E '/time|dev|uid/s/[0-9]+/N/g'"
note 'size is the length of the file on disk. Here it equals the size of the blob.'
run 'git cat-file -s :src/app.py'

snip 02-touch
note 'Change the modification time of the file. The content stays the same.'
run 'touch -t 202001010000 src/app.py'
note 'Plumbing compares stat data only, and reports the entry as possibly changed.'
run 'git diff-files'

snip 03-refresh
note 'Porcelain re-reads the file, finds the same content, and stores the new stat data.'
run 'git status --short'
run 'git diff-files'

snip 04-refresh-by-hand
run 'touch -t 202101010000 src/app.py'
run 'git diff-files --name-status'
run_rc 'git update-index --refresh'
run 'git diff-files --name-status'

snip 05-real-change
note 'A real edit: refresh cannot make this entry match, and says so.'
run "echo 'TOP_K = 10' > src/retriever.py"
run_rc 'git update-index --refresh'
run 'git diff-files'

lab_end
