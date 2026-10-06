#!/usr/bin/env bash
# Lab 36.4, failure scenario and recovery: reverting a merge to "get the fix back" removes the
# feature instead; and what reverting the faulty merge itself does.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-36-4-misunderstood-conflict
incident_load 09-misunderstood-conflict

snip 01-failure
run 'cd you'
pr=$(git log --merges --format=%h --grep='pull request' main)
inner=$(git log --merges --format=%h --grep='remote-tracking' main)
note 'The tempting move: revert the pull request merge that "lost" the fix.'
run "git revert --no-edit -m 1 $pr"
run 'git show --stat --format=%s HEAD'
run 'ls limiter'
run 'cat limiter/bucket.py'

snip 02-revert-inner-merge
note 'Undo that (nothing was pushed), and try the merge that made the bad resolution:'
run 'git reset --keep origin/main'
run_rc "git revert --no-edit -m 1 $inner"
run 'git status -sb'

snip 03-recovery
note 'The fix is a new commit, as in the solution:'
quiet 'git revert --abort; git reset --keep origin/main'
quiet "sed -i.bak -e 's/^DEFAULT_RATE = 100\$/DEFAULT_RATE = 50/' -e 's/bucket.tokens = bucket.tokens + (now - bucket.ts) \\* rate/bucket.tokens = min(BURST, bucket.tokens + (now - bucket.ts) * rate)/' limiter/bucket.py && rm limiter/bucket.py.bak"
run 'git diff --stat'
run "git commit -a -m 'Restore the burst cap and the lowered default rate'"
run 'git push'
run 'cd ..'
show_check
incident_done
