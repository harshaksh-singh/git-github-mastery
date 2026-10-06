#!/usr/bin/env bash
# Chapter 9, section 9.17: the explicit form of the lease. You write down which commit you expect
# the server to have. A background fetch cannot weaken that, because the expected value no longer
# comes from the remote-tracking branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 force-lease-explicit
fx_shared_branch asha-pushed

snip 01-record-and-rebase
note 'Before rewriting, record what the server had when you last looked.'
run 'git rev-parse origin/feat/ingest'
run 'git rebase main'

snip 02-fetch-then-push
note 'Asha pushed in the meantime, and something fetched for you. The explicit lease still refuses:'
run 'git fetch'
run_rc 'git push --force-with-lease=feat/ingest:dc5df9356273e7c0c2807ce808c378782ea2525a'

snip 03-bare-lease-would-pass
run 'git push --force-with-lease --dry-run'
lab_end
