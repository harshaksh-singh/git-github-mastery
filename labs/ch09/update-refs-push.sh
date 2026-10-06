#!/usr/bin/env bash
# Chapter 9, section 9.9: publishing a rebased stack. After "git rebase --update-refs" three local
# branches have moved, so three branches on the server are out of date. One push updates them all,
# each ref with its own lease.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 update-refs-push
fx_server_init
cd you || exit 1
_fx_ingest_loader
git switch -q -c feat/ingest-cleaner
put ingest/cleaner.py <<'PYEOF'
def clean(text):
    return " ".join(text.split())
PYEOF
commit_all "Add text cleaner"
git switch -q -c feat/ingest-chunker
put ingest/chunker.py <<'PYEOF'
def chunk(text, size=800):
    return [text[i:i + size] for i in range(0, len(text), size)]
PYEOF
commit_all "Add chunker"
git push -q -u origin feat/ingest-loader feat/ingest-cleaner feat/ingest-chunker > /dev/null 2>&1
git switch -q main
put README.md <<'MDEOF'
# ragkit

Retrieval-augmented answering service.
MDEOF
commit_all "Add README"
git push -q origin main > /dev/null 2>&1
git switch -q feat/ingest-chunker
as config

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-rebase
run 'git rebase --update-refs main'
run 'git branch -vv'

snip 03-push-the-stack
run 'git push --force-with-lease --force-if-includes origin feat/ingest-loader feat/ingest-cleaner feat/ingest-chunker'

snip 04-after
run 'git log --oneline --graph --decorate --all'
lab_end
