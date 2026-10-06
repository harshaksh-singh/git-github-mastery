#!/usr/bin/env bash
# Lab 29.1 replay: the evidence for five workflows (not the analysis), a scan that misses
# something, and the scan that does not.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21a lab-29-1-inventory
. "$LAB_SCRIPT_DIR/fixture.bash"
wf_repo
cd .github/workflows || exit 1

snip 01-files
run 'ls v*.yml'
run "grep -c '' v*.yml"

snip 02-triggers
run "grep -n -A3 '^on:' v*.yml"

snip 03-permissions
run "grep -n -A2 '^permissions:' v*.yml"

snip 04-uses
run "grep -n 'uses:' v*.yml"

snip 05-secrets-and-tokens
run "grep -n 'secrets\\.\\|github\\.token' v*.yml"

snip 06-narrow-scan
note 'A scan that looks convincing: expressions on a line that starts a run step.'
run_rc "grep -n 'run:.*\${{' v*.yml"

snip 07-wide-scan
note 'Every expression, with its line number. Classify each one by hand: is it inside a script?'
run "grep -n '\${{' v*.yml"

snip 08-run-blocks
note 'The lines of every multi-line script (from "run: |" to the next step or job).'
run "awk '/run: \\|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:\$/ {inrun=0} inrun && /\\\$\\{\\{/ {print FILENAME \":\" FNR \":\" \$0}' v*.yml"

lab_end
