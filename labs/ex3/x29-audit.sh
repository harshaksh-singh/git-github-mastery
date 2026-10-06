#!/usr/bin/env bash
# Exercises 29.2 to 29.4 (Module 29): the five review questions of Chapter 21A, section
# 21A.16, asked with grep of the three teaching workflows in exercises/workflows/.
# Plain grep on files of this course. Nothing runs on GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex3 x29-audit
mkdir -p wf && cp "$COURSE_ROOT"/exercises/workflows/x29-*.yml wf/ || exit 1
cd wf || exit 1

snip 01-triggers-permissions
run "grep -n -A3 '^on:' x29-*.yml | grep -v -- '--'"
run "grep -n -A3 '^permissions:' x29-*.yml | grep -v -- '--'"

snip 02-uses
run "grep -n 'uses:' x29-*.yml | grep -v -E '@[0-9a-f]{40} # v[0-9]'"

snip 03-expressions-in-run
note 'An expression on a "run:" line, or on a line of a script (a line that is not "key: value"):'
run_rc "grep -n 'run:.*[$]{{' x29-*.yml"
run "grep -n '[$]{{' x29-*.yml | grep -v -E ':[0-9]+: +(- )?[A-Za-z_-]+: '"

snip 04-runners-remote-code
run "grep -n -E 'runs-on:|curl|toJSON|secrets: inherit|enable-cache|environment:' x29-*.yml"

lab_end
