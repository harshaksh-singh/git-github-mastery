#!/usr/bin/env bash
# Lab 11.2 replay: a log message has disappeared from the nightly output. Find the commit that removed
# the string with -S, then see with -G what -S did not report. The failure scenario searches for an
# over-specific string and names the wrong commit.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-2-pickaxe-removed-string
fx_scorekit || exit 1

snip 01-gone
run_rc 'git grep -n "skipped empty reference"'

snip 02-S
run "git log --format='%h %ad %<(10)%an %s' --date=short -S'skipped empty reference'"

snip 03-removal
removal=$(git log --format=%h -1 -S'skipped empty reference')
run "git show $removal"

snip 04-G
run "git log --format='%h %ad %<(10)%an %s' --date=short -G'skipped empty reference'"

snip 05-what-G-saw
run "git log -p --format='commit %h %s' -G'skipped empty reference' -- scorekit/runner.py | grep -E '^commit|^[-+].*skipped'"

snip 06-line-history
note "The same story as line history, starting from the last commit that still had the line ($removal~1):"
run "git log -s --format='%h %s' -L '/skipped empty reference/,+1:scorekit/runner.py' $removal~1"

snip 07-failure
note 'A colleague copies the whole statement from an old log-parsing script and searches for that:'
run "git log --format='%h %ad %<(10)%an %s' --date=short -S\"print('skipped empty reference')\""

snip 08-diagnose
wrong=$(git log --format=%h -1 -S"print('skipped empty reference')")
run "git show --format='%h %an: %s' $wrong"

snip 09-recovery
run "git grep -c 'skipped empty reference' $wrong~1 $wrong -- scorekit/runner.py"
run "git log --oneline -S'skipped empty reference'"

snip 10-verification
run "git grep -c 'skipped empty reference' $removal~1 -- scorekit/runner.py"
run_rc "git grep -c 'skipped empty reference' $removal -- scorekit/runner.py"
lab_end
