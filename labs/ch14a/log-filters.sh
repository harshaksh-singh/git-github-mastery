#!/usr/bin/env bash
# Chapter 14A, section 14A.9: commit-limiting options of git log: author, committer, message, date,
# path; and what each commit shows once it is selected (--stat, -p).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-filters
fx_scorekit || exit 1

snip 01-author
run 'git log --oneline --author=Ravi'
run "git log --format='%h %an (committed by %cn) %s' --author=Ravi --committer='Lab User'"

snip 02-grep
run 'git log --oneline --grep=crash'
run 'git log --oneline -i --grep=rouge'
run 'git log --oneline -i --grep=rouge --all'
run 'git log --oneline --grep=limit --grep=crash'
run 'git log --oneline --grep=limit --grep=crash --all-match'

snip 03-dates
run "git log --oneline --since='2026-09-10 00:00' --until='2026-09-11 00:00'"
run "git log --oneline --since='2 days ago'"

snip 03b-time-of-day
now=$(( (_lab_clock + 60 + 19800) % 86400 ))
note "A date without a time takes the current time of day. The lab clock reads $(printf '%02d:%02d' $((now / 3600)) $((now % 3600 / 60)))."
run 'git log --oneline --since=2026-09-10 --until=2026-09-11'

snip 04-committer-date
note '--since and --until test the committer date. The newest commit was authored at 10:46 and committed at 12:41:'
run "git log --format='%h authored %ad, committed %cd' --date=format:'%a %H:%M' --since='2026-09-15 12:30'"

snip 05-paths
run 'git log --oneline -- scorekit/config.py'
run "git log --oneline v0.2.0..main -- docs scorekit/metrics.py"

snip 06-stat-patch
run "git log --stat --format='%h %s' -2 -- scorekit/config.py"
run "git log -p --format='%h %s' -1 -- scorekit/config.py"
lab_end
