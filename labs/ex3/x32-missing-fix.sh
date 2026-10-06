#!/usr/bin/env bash
# Exercise 32.5 (Module 32), model solution: which fixes on the release branch never reached
# main? The hands-on twin is setup-x32-5-missing-fix.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x32-missing-fix
scenario_x32_missing_fix

snip 01-state
run 'git log --graph --oneline --decorate main release/2.3'

snip 02-ancestry
run_rc 'git merge-base --is-ancestor release/2.3 main'
run 'git log --oneline main..release/2.3'

snip 03-patch-check
run 'git log --cherry-pick --right-only --oneline main...release/2.3'

snip 04-read-the-candidates
run "git log --format='%h %s%n%b' main..release/2.3 | grep -E '^[0-9a-f]{7} |cherry picked'"
SUSPECT=$(git log --format=%h --grep='reject a chunk size' release/2.3 -1)
ORIG=$(git log --format=%h --grep='reject a chunk size' main -1)
run_rc "git grep -n 'size must be positive' main -- chunker/split.py"
run_rc "git grep -n 'max_chunks' main"

snip 05-port
MISSING=$(git log --format=%h --grep='cap the number of chunks' release/2.3 -1)
run "git cherry-pick -x $MISSING"
run "git log -1 --format='%h %s%n%n%b'"
run_rc "git grep -n 'max_chunks' main"
run 'git log --cherry-pick --right-only --oneline main...release/2.3'

lab_end
