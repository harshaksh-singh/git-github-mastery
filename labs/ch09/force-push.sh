#!/usr/bin/env bash
# Chapter 9, section 9.17: publishing a rebased branch. A plain push is rejected; --force-with-lease
# refuses when the server moved since your last fetch; after a background fetch only
# --force-if-includes still refuses; the fix is to rebase what is really on the server.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 force-push
fx_shared_branch asha-pushed

snip 01-rebase
note 'Asha pushed "Add chunker" to feat/ingest after your last fetch. You do not know that yet.'
run 'git rebase main'
run 'git log --oneline --graph --decorate --all'

snip 02-plain-push
run_rc 'git push'

snip 03-lease
run_rc 'git push --force-with-lease'

snip 04-background-fetch
note 'Something fetches for you: an editor, a status prompt, or you out of habit.'
run 'git fetch'
note 'The lease now compares against the freshly fetched value. A dry run shows it would overwrite:'
run 'git push --force-with-lease --dry-run'

snip 05-if-includes
run_rc 'git push --force-with-lease --force-if-includes'

snip 06-integrate
note 'Rebase what is really on the server, then publish with both checks.'
run 'git reset --hard origin/feat/ingest'
run 'git rebase main'
run 'git push --force-with-lease --force-if-includes'

snip 07-result
run 'git log --oneline --graph --decorate --all'
lab_end
