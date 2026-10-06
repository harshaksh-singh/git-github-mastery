#!/usr/bin/env bash
# Chapter 11, section 11.11: two refusals of "git stash pop" when the entry was made with -u.
# First the pop is refused because a file it must change has a local edit, yet the untracked
# file from the entry is written anyway. Then, with the edit out of the way, the tracked part
# applies and the untracked part is refused because the file now exists. The entry is kept
# both times, so the last step compares the entry with the working tree and drops it by hand.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 stash-untracked-trap

quiet 'git init gateway'
cd gateway || exit 1
quiet "printf 'def route(request):\n    return upstream(request.model)\n' > router.py && printf 'requests_per_minute: 60\nburst: 10\n' > limits.yaml && git add . && git commit -m 'Add request router and rate limits'"
quiet "printf 'requests_per_minute: 120\nburst: 10\n' > limits.yaml"
quiet "printf 'Per-tenant limits: decide the default quota.\n' > notes.md"
quiet 'git stash push -u -m "wip: per-tenant limits"'
# Later, a different edit to the same file, not committed.
quiet "printf 'requests_per_minute: 60\nburst: 20\n' > limits.yaml"

snip 01-refused-but-not-untouched
run 'git stash show --include-untracked'
run 'git status -s'
run_rc 'git stash pop'
run 'git status -s'

snip 02-half-applied
run 'git restore limits.yaml'
run_rc 'git stash pop'
run 'git status -s'
run 'git stash list'

snip 03-compare-then-drop
note 'Tracked part: the working tree against the stash commit. No output means identical.'
run "git diff 'stash@{0}' -- limits.yaml"
note 'Untracked part: it lives in the third parent of the stash commit.'
run_rc "git show 'stash@{0}^3:notes.md' | diff - notes.md"
run 'git stash drop'

lab_end
