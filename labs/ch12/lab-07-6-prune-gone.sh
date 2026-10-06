#!/usr/bin/env bash
# Lab 7.6 replay: stale remote-tracking refs, a fetch blocked by a ref name conflict,
# pruning, branches whose upstream is gone, and a deleted branch that a push brings back.
# Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-6-prune-gone
scenario_07_6

snip 01-stale-view
run 'cd you/support-bot'
run 'git branch -vv'
run 'git branch -r'
run 'git ls-remote --branches origin'

snip 02-fetch-blocked
run_rc 'git fetch'

snip 03-prune
run 'git remote prune --dry-run origin'
run 'git fetch --prune'
run 'git branch -r'

snip 04-gone
run 'git branch -vv'
run 'git for-each-ref --format="%(refname:short) %(upstream:track)" refs/heads | grep -F "[gone]"'

snip 05-delete-merged
run 'git pull --ff-only'
run 'git branch -d feature/reranker'

snip 06-delete-unmerged
run_rc 'git branch -d spike/hybrid-search'
run 'git log --oneline main..spike/hybrid-search'
run 'git branch -D spike/hybrid-search'

snip 07-prune-by-default
run 'git config set fetch.prune true'
run 'git config get --show-origin fetch.prune'

snip 08-checkpoint
run 'git branch -vv'
run 'git branch -r'

snip 09-failure
run 'git switch feature/eval-harness'
as asha
run 'git -C ../../asha/support-bot push origin --delete feature/eval-harness'
as you
run 'git fetch'
run 'git status'
run 'git push'
run 'git ls-remote --branches origin'

snip 10-recovery
run 'git push origin --delete feature/eval-harness'
run 'git branch --unset-upstream'
run_rc 'git push'

snip 11-verification
run 'git ls-remote --branches origin'
run 'git branch -vv'

lab_end
