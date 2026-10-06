#!/usr/bin/env bash
# Lab 10.3 replay: find out which fixes from main are already on the maintenance branch. "git cherry"
# finds exact copies by patch ID; a backport whose conflict was resolved by hand escapes it and is found
# through its "cherry picked from" line. The failure scenario trusts "git cherry" alone.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 lab-10-3-detect-duplicates
fx_gateway_duplicates

snip 01-start
run 'git log --graph --decorate --all --format="%h %an: %s%d"'

snip 02-cherry
run 'git cherry -v release/1.4 main'

snip 03-cherry-mark
run 'git log --oneline --left-right --cherry-mark release/1.4...main'

snip 04-trailers
run 'git log --format="%h %s%n   %b" main..release/1.4'

snip 05-missing
note 'Asha fixed three things on main. Two are on the release under other IDs. The third is missing:'
run 'git log --oneline --author=Asha main'
run 'git cherry-pick -x main~1'

snip 06-failure
note 'A colleague reads the "+" in front of "Retry failed generate calls" as "not backported yet":'
run_rc 'git cherry-pick -x main~2'

snip 07-diagnose
run 'git status --short'
run 'git log --oneline --grep="cherry picked from commit $(git rev-parse main~2)" release/1.4'

snip 08-recovery
run 'git cherry-pick --abort'
run 'git status --short --branch'

snip 09-verification
run 'git log --oneline --decorate -4'
run 'git cherry -v release/1.4 main'
lab_end
