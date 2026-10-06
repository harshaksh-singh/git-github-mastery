#!/usr/bin/env bash
# Replay of Exercise 10.10 (Level 5, "the fix is in the release" against "the fix was never
# backported"): diagnosis and repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m10-half-backport
exercise_load m10-half-backport

snip 01-claims
run 'cd you'
fix=$(git log --format=%h -1 --grep='ROUTE-231' origin/main)
note "Asha's command: which branches contain the commit that the ticket names?"
run "git branch -r --contains $fix"
note "Ravi's command: is there a commit on the release line that mentions the ticket?"
run 'git log --oneline origin/release/2.x --grep=ROUTE-231'

snip 02-graph
run 'git log --graph --oneline origin/main origin/release/2.x'

snip 03-equivalence
note 'Which commits of main have a copy with the same change on the release line?'
run 'git cherry -v origin/release/2.x origin/main'
run 'git log --oneline --left-right --cherry-mark origin/release/2.x...origin/main'

snip 04-content
run 'git diff origin/release/2.x origin/main -- router/select.py'
run 'git log --oneline origin/release/2.x..origin/main -- router/select.py'

snip 05-backport
missing=$(git log --format=%h -1 --grep='exactly the limit' origin/main)
run 'git switch release/2.x'
run "git cherry-pick -x $missing"
run 'git log -1 --format=%B'

snip 06-verify
run_rc 'git diff --quiet HEAD origin/main -- router/select.py'
run 'git diff --stat HEAD origin/main'
run 'git cherry -v HEAD origin/main'

snip 07-publish
run 'git push'
run 'git log --oneline -4 origin/release/2.x'

snip 08-check
run 'cd ..'
show_check
exercise_done
